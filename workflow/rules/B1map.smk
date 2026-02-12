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

#maybe implement mri_synthmorph instead?
rule synthstrip_b1anat:
    input:
        get_last_b1anat_run,
        check_csa_added_to_meta
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain.nii.gz"),
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads:
        4
    shell:
        """
        mri_synthstrip -i {input[0]} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        """

rule DenoiseImage_b1anat: #ATTENTION: slighlty different parameters from MPM/VFA
    input:
        input_image = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        DenoiseImage -d 3 -n Rician -s 1 -v 1 -p 1 -r 2 -i {input.input_image} -x {input.mask_image} -o {output}
        """

rule N4BiasFieldCorrection_b1anat: #ATTENTION: slightly different parameters from MPM/VFA
    input:
        input_image = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        N4BiasFieldCorrection -d 3 -s 1 -v 1 -c [ 50x50x50x50, 0 ] -i {input.input_image} -x {input.mask_image} -o {output}
        """

rule register_b1anat_to_mp2rage: #ATTENTION: slightly different parameters from MPM/VFA
    input:
        ref = "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_brain_denoised_n4_registeredtoMP2RAGE.nii.gz"),
        temp("data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_n4_registeredtob1anat.nii.gz"),
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_registeredtoMP2RAGE_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Rigid[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/B1map/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-anat_registeredtoMP2RAGE_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """

rule apply_reg_b1_to_mp2rage: #ATTENTION: some parameters are different from MPM/VFA
    input:
        check_csa_added_to_meta,
        ref = "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_n4.nii.gz",
        moving = get_last_b1map_run,
        reg = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-anat_registeredtoMP2RAGE_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -n Linear --output-data-type short -v 1 -f 0 -i {input.moving} -r {input.ref} -t {input.reg} -o {output}
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

rule smooth_B1:
    input:
        get_last_b1map_run,
        check_csa_added_to_meta
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """

rule reslice_B1:
    input:
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz",
        ref = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -r {input.ref} -i {input.b1map} -o {output}
        """

rule normalize_B1_to_target_flip:
    input:
        fmap = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w.nii.gz",
        mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.fmap} -mas {input.mask} -div {params.target_flip} {output} -odt float 
        """