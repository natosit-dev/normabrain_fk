import json
import glob
import shutil

def get_target_flip(wildcards):
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.json'))[-1] #select last run
    with open(json_path, "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_last_b1map_run(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.nii.gz'))[-1]

def get_last_b1anat_run(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-anat*_TB1TFL.nii.gz'))[-1]


rule register_b1anat_to_MP2RAGE:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.nii.gz",
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredtoMP2RAGE.lta"
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
    

rule apply_reg_b1map_to_MP2RAGE:
    input:
        check_csa_added_to_meta,
        moving = get_last_b1map_run,
        reg = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredtoMP2RAGE.lta"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: #-H option means no resampling: MP2PROC does resampling and there's no way to turn it off
        """
        mri_synthmorph apply -H {input.reg} {input.moving} {output}
        """ 


rule copy_b1map_json_after_regtoMP2RAGE:
    input:
        check_csa_added_to_meta,
        b1map_raw = get_last_b1map_run,
        b1map_registeredtoMP2RAGE = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.json"
    run:
        b1map_raw_json = Path(input.b1map_raw).with_suffix("").with_suffix(".json")
        b1map_registeredtoMP2RAGE_json = Path(input.b1map_registeredtoMP2RAGE).with_suffix("").with_suffix(".json")
        shutil.copy(b1map_raw_json, b1map_registeredtoMP2RAGE_json)


rule register_b1anat_to_MPM_t1w:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz",
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredto{seq}t1w.lta"
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


rule apply_reg_b1map_to_MPM_t1w:
    input:
        check_csa_added_to_meta,
        moving = get_last_b1map_run,
        reg = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredto{seq}t1w.lta"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: #register and reslice to MPM t1w
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """  


rule smooth_B1:
    input:
       "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w.nii.gz" 
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """


rule normalize_B1_to_target_flip: #not masking because we are interested in the spinal cord
    input:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input} -div {params.target_flip} {output} -odt float 
        """