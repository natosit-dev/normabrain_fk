import json
import glob
import shutil

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_target_flip(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.json'))[-1] #select last run
    with open(json_path, "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10

def get_last_b1map_run(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.nii.gz'))[-1]

def get_last_b1anat_run(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-anat*_TB1TFL.nii.gz'))[-1]


rule register_b1anat_to_MP2RAGE:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.nii.gz"
    params:
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredtoMP2RAGE.lta"
    threads: 4
    container:
        "docker://freesurfer/synthmorph:4"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthmorph register -g -m rigid -t {output} {params.moving} {input.ref}
        else
            mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref}
        fi
        """
    

rule apply_reg_b1map_to_MP2RAGE:
    input:
        check_csa_added_to_meta,
        reg = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredtoMP2RAGE.lta"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz"
    container:
        "docker://freesurfer/synthmorph:4"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell: #-H option means no resampling: MP2PROC does resampling and there's no way to turn it off
        """
        mri_synthmorph apply -H {input.reg} {params.moving} {output}
        """ 


rule copy_b1map_json_after_regtoMP2RAGE:
    input:
        check_csa_added_to_meta,
        b1map_registeredtoMP2RAGE = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz"
    params:
         b1map_raw = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.json"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    run:
        b1map_raw_json = Path(params.b1map_raw).with_suffix("").with_suffix(".json")
        b1map_registeredtoMP2RAGE_json = Path(input.b1map_registeredtoMP2RAGE).with_suffix("").with_suffix(".json")
        shutil.copy(b1map_raw_json, b1map_registeredtoMP2RAGE_json)


rule register_b1anat_to_MPM_t1w:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz"
    params:
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredto{seq}t1w.lta"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    container:
        "docker://freesurfer/synthmorph:4"
    shell:
        """
        mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref}
        """


rule apply_reg_b1map_to_MPM_t1w:
    input:
        check_csa_added_to_meta,
        reg = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_B1registeredto{seq}t1w.lta"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w.nii.gz"
    container:
        "docker://freesurfer/synthmorph:4"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell: #register and reslice to MPM t1w
        """
        mri_synthmorph apply {input.reg} {params.moving} {output}
        """  


rule smooth_B1:
    input:
       "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w.nii.gz" 
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """


rule normalize_B1_to_target_flip: #not masking because we are interested in the spinal cord
    input:
        check_csa_added_to_meta,
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input[1]} -div {params.target_flip} {output} -odt float 
        """