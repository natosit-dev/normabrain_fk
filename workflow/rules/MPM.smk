import json
import glob

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"]

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_echos(wildcards):
    #get the list of echo files, sort it, and then return the first N echos as specified in the config file
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}*_echo-*_flip-*_mt-{wildcards.mt}_part-{wildcards.part}_MPM.nii.gz'))[:config["n_echos"]]

def get_qMT_params(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mtw*_echo-1_flip-*_mt-on_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        mtw_meta = json.load(f)
        mt_params = {
            'mtflip' : mtw_meta["FlipAngle"],
            'sat_pulse_ms' : mtw_meta['sat_pulse_ms'],
            'interdelay_ms' : mtw_meta['interdelay_ms'],
            'ro_pulse_ms' : mtw_meta['ro_pulse_ms'],
            'tr_ms' : mtw_meta['tr_ms'],
            'ro_fa_deg' : mtw_meta['ro_fa_deg'],
            'ro_pulse_shape' : mtw_meta['ro_pulse_shape'],
            'sat_pulse_fa_deg' : mtw_meta['sat_pulse_fa_deg'],
            'sat_pulse_offset_hz' : mtw_meta['sat_pulse_offset_hz'],
            'sat_pulse_shape' : mtw_meta['sat_pulse_shape']
        }
    return mt_params

def get_t1flip(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}t1w*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        t1w_meta = json.load(f)
    return t1w_meta["FlipAngle"]

def get_pdflip(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}pdw*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        pdw_meta = json.load(f)
    return pdw_meta["FlipAngle"]


rule sos:
    input:
        meta_complete = check_csa_added_to_meta,
        echos = get_echos
    params:
        files=lambda wildcards, input: ','.join(input.echos)
    output:
       "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz"
    conda:
        "../envs/qMT.yaml"
    threads: 2
    shell:
        """
        python3 workflow/scripts/sos_images.py {params.files} {output}
        """


rule synthstrip_MPM:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain.nii.gz"),
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
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


rule install_sct:
    output:
        ".snakemake/scripts/install_sct.done"
    shell: #Check if sct is already installed. If not, install version 7.2 for linux.
        """
        if ! command -v sct_deepseg; then
            if [[ $(uname) == Darwin* ]]; then
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_macos.sh
            else
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_linux.sh
            fi
            mv install_sct-7.2_*.sh .snakemake/scripts/
            bash .snakemake/scripts/install_sct-7.2_*.sh -y    
        fi
        touch .snakemake/scripts/install_sct.done
        """


rule spineseg_MPM:
    input:
       "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
       ".snakemake/scripts/install_sct.done"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_all.nii.gz",
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_discs.nii.gz"),
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_discs.json")
    # container:
    #     "docker://vnmd/spinalcordtoolbox_7.2:20251215"
    threads: 8
    shell:
        """
        sct_deepseg spine -i {input[0]}
        """


rule brain_and_spine_mask_MPM:
    input:
       spine_seg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_all.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        spine_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz",
        brain_spine_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_spine_mask.nii.gz"  
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.spine_seg} -bin {output.spine_mask}
        fslmaths {input.brain_mask} -add {output.spine_mask} {output.brain_spine_mask}
        """


rule register_MPM_to_t1w:
    input:
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_registeredto{seq}t1w.lta"
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
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_registeredto{seq}t1w.lta"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_registeredto{seq}t1w.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: 
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """


rule mtr:
    input:
        mt_off = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_sos_registeredto{seq}t1w.nii.gz",
        mt_on = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_sos_registeredto{seq}t1w.nii.gz"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_MTRmap.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        """


rule setup_fit_JSPqMT_CLI:
    output:
        directory("workflow/scripts/luca_qMT/build/")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        cd workflow/scripts/luca_qMT/
        python3 setup.py build_ext --inplace
        """


rule fit_JSPqMT_CLI:
    input:
        meta_complete = check_csa_added_to_meta,
        build = "workflow/scripts/luca_qMT/build/",
        mt_off = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_sos_registeredto{seq}t1w.nii.gz",
        mt_on = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_sos_registeredto{seq}t1w.nii.gz",
        pdw = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_sos_registeredto{seq}t1w.nii.gz",
        t1w = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz",
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_spine_mask.nii.gz"
    params:
        mt_params = get_qMT_params,
        t1flip = get_t1flip,
        pdflip = get_pdflip
    output:
        mpfmap = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_MPFmap.nii.gz",
        t1map = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        r1map = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_R1map.nii.gz"
    threads: 8
    conda:
        "../envs/qMT.yaml"
    # container:
    #     "docker://hugodary/vibe_mt:latest"
    shell:
        """
        python3 workflow/scripts/luca_qMT/fit_JSPqMT_CLI.py \
        {input.mt_off},{input.mt_on} \
        {input.pdw},{input.t1w} \
        {output.mpfmap} \
        {output.t1map} \
        --R1f {output.r1map} \
        --MTw_TIMINGS {params.mt_params[sat_pulse_ms]},{params.mt_params[interdelay_ms]},{params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_TIMINGS {params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_PARX {params.pdflip},{params.t1flip},{params.mt_params[ro_pulse_shape]} \
        --MTw_PARX {params.mt_params[ro_fa_deg]},{params.mt_params[ro_pulse_shape]},{params.mt_params[sat_pulse_fa_deg]},{params.mt_params[sat_pulse_offset_hz]},{params.mt_params[sat_pulse_shape]} \
        --B1 {input.b1map} \
        --mask {input.mask} \
        --nworkers {threads} \
        --cpp_opt --use_GBM
        """


rule register_qT1_MPM_to_MP2RAGE:
    input:
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE.lta"
    threads: 4
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        if command -v nvcc --version && command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthmorph register -g -m affine -t {output} {input.moving} {input.ref}
        else
            mri_synthmorph register -m affine -t {output} {input.moving} {input.ref}
        fi
        """


rule apply_reg_qT1_MPM_to_MP2RAGE:
    input:
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE.lta"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_registeredtoMP2RAGE.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: #register and reslice to MP2RAGE
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """  
