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


#rules for registering with ANTs

rule synthstrip_b1anat:
    input:
        check_csa_added_to_meta
    params:
        get_last_b1anat_run
    output:
        # "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.nii.gz",
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {params} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {params} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_b1anat:
    input:
        check_csa_added_to_meta,
        brain_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    params:
        get_last_b1anat_run
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {params} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_b1anat: #ATTENTION: slighlty different parameters from MPM/VFA
    input:
        input_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        DenoiseImage -d 3 -n Rician -s 1 -v 1 -p 1 -r 2 -i {input.input_image} -x {input.mask_image} -o {output}
        """

rule N4BiasFieldCorrection_b1anat: #ATTENTION: slightly different parameters from MPM/VFA
    input:
        input_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        N4BiasFieldCorrection -d 3 -s 1 -v 1 -c [ 50x50x50x50, 0 ] -i {input.input_image} -x {input.mask_image} -o {output}
        """


rule register_b1anat_to_mp2rage: #ATTENTION: slightly different parameters from MPM/VFA
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4_registeredtoMP2RAGE_ants.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_n4_registeredtoB1anat_ants.nii.gz"),
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_B1registeredtoMP2RAGE_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Rigid[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/B1map/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/{wildcards.subject}_{wildcards.session}_B1registeredtoMP2RAGE_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """

rule apply_reg_b1_to_mp2rage: #ATTENTION: some parameters are different from MPM/VFA
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1.nii.gz",
        reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_B1registeredtoMP2RAGE_0GenericAffine.mat"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_ants.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        antsApplyTransforms -d 3 -n Linear --output-data-type short -v 1 -f 0 -i {params.moving} -r {input.ref} -t {input.reg} -o {output}
        """

rule register_b1anat_to_MPM_t1w_ants: #ATTENTION: slightly different parameters from MPM/VFA
    input:
        ref = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask ="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4_registeredto{seq}t1w_ants.nii.gz"),
        temp("data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_denoised_n4_registeredtob1anat.nii.gz"),
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredto{seq}t1w_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Rigid[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --collapse-output-transforms 1 --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/B1map/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_B1registeredto{wildcards.seq}t1w_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """

rule apply_reg_b1map_to_MPM_t1w_ants: #ATTENTION: some parameters are different from MPM/VFA
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_denoised_n4.nii.gz",
        reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredto{seq}t1w_0GenericAffine.mat"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_ants.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        antsApplyTransforms -d 3 -n Linear --output-data-type short -v 1 -f 0 -i {params.moving} -r {input.ref} -t {input.reg} -o {output}
        """


#rules for registering with synthmorph

rule register_b1anat_to_MP2RAGE_synthmorph:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/uncorr_qT1.nii.gz"
    params:
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredtoMP2RAGE_synthmorph.lta"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources: 
        mem_mb=7000
    shell:
        """
        mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref}
        """
    

rule apply_reg_b1map_to_MP2RAGE_synthmorph:
    input:
        check_csa_added_to_meta,
        reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredtoMP2RAGE_synthmorph.lta"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_synthmorph.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources: 
        mem_mb=500
    shell: #-H option means no resampling: MP2PROC does resampling and there's no way to turn it off
        """
        mri_synthmorph apply -H {input.reg} {params.moving} {output}
        """ 

rule register_b1anat_to_MPM_t1w_synthmorph:
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz"
    params:
        moving = get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredto{seq}t1w_synthmorph.lta"
    threads: 4
    resources: 
        mem_mb=7000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output} {params.moving} {input.ref}
        """


rule apply_reg_b1map_to_MPM_t1w_synthmorph:
    input:
        check_csa_added_to_meta,
        reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_B1registeredto{seq}t1w_synthmorph.lta"
    params:
        moving = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_synthmorph.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources: 
        mem_mb=500
    shell: #register and reslice to MPM t1w
        """
        mri_synthmorph apply {input.reg} {params.moving} {output}
        """  


#Post registration rules

rule copy_b1map_json_after_regtoMP2RAGE:
    input:
        check_csa_added_to_meta,
        b1map_registeredtoMP2RAGE = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_ants.nii.gz"
    params:
         b1map_raw = get_last_b1map_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_ants.json"
    resources: 
        mem_mb=300
    run:
        b1map_raw_json = Path(params.b1map_raw).with_suffix("").with_suffix(".json")
        b1map_registeredtoMP2RAGE_json = Path(input.b1map_registeredtoMP2RAGE).with_suffix("").with_suffix(".json")
        shutil.copy(b1map_raw_json, b1map_registeredtoMP2RAGE_json)


rule smooth_B1:
    input:
       "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_ants.nii.gz" 
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """


rule normalize_B1_to_target_flip: #not masking because we are interested in the spinal cord
    input:
        check_csa_added_to_meta,
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_smooth.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp_registeredto{seq}t1w_smooth_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input[1]} -div {params.target_flip} {output} -odt float 
        """