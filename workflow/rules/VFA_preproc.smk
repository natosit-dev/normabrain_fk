import glob

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["VFA_contrasts"]]),
    seq = config["VFA_sequence"],

def get_echos(wildcards):
    #get the list of echo files, sort it, and then return the first N echos as specified in the config file
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}*_echo-*_flip-*_mt-{wildcards.mt}_part-{wildcards.part}_MPM.nii.gz'))[:config["n_echos"]]

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]


rule SoS:
    input:
        meta_complete = check_csa_added_to_meta,
        echos = get_echos
    params:
        files=lambda wildcards, input: ','.join(input.echos)
    output:
       "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    conda:
        "../envs/qMT.yaml"
    threads: 2
    shell:
        """
        python3 workflow/scripts/SoS_images_CLI.py {params.files} {output}
        """


rule synthstrip_mpm:
    input:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain.nii.gz"),
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    shell:
        """
        if command -v nvcc --version && command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf -g
        else 
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        fi
        """


rule spineseg_mpm:
    input:
       "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_totalspineseg_all.nii.gz",
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_totalspineseg_discs.nii.gz"),
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_totalspineseg_discs.json")
    container:
        "docker://vnmd/spinalcordtoolbox_7.2:20251215"
    threads: 4
    shell:
        """
        sct_deepseg spine -fill-holes 1 -i {input}
        """


rule brain_and_spine_mask_mpm:
    input:
       spine_seg = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_totalspineseg_all.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        spine_mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_spine_mask.nii.gz",
        brain_spine_mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_spine_mask.nii.gz"  
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.spine_seg} -bin {output.spine_mask}
        fslmaths {input.brain_mask} -add {output.spine_mask} {output.brain_spine_mask}
        """


rule register_MPM_to_t1w:
    input:
        ref = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS.nii.gz",
        moving = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_registeredto{seq}t1w.lta"
    threads: 4
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        if command -v nvcc --version && command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthmorph register -g -m rigid -t {output} {input.moving} {input.ref}
        else
            mri_synthmorph register -m rigid -t {output} {input.moving} {input.ref}
        fi
        """


rule apply_reg_MPM_to_t1w:
    input:
        moving = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz",
        reg = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_registeredto{seq}t1w.lta"
    output:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_registeredto{seq}t1w.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: 
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """