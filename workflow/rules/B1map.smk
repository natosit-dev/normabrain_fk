import json
def get_target_flip(wildcards):
    with open(f"data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp{wildcards.run}_TB1TFL.json", "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

#TO DO: implement checkpoint for BIDS
wildcard_constraints:
    run=".*", #run can be an empty string
    # t1flip=r"\d+" #t1flip should be a number

rule smooth_B1:
    input:
        "data/rawdata/bids/{field_strength}/sub-{subject}/ses-{session}/fmap/sub-{subject}_ses-{session}_acq-famp{run}_TB1TFL.nii.gz",
        # rules.add_csa_data_to_meta.output
        check_csa_added_to_meta
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp{run}_smooth.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """

rule reslice_B1:
    input:
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth.nii.gz",
        ref = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -r {input.ref} -i {input.b1map} -o {output}
        """

rule normalize_B1_to_target_flip:
    input:
        fmap = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM.nii.gz",
        mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.fmap} -mas {input.mask} -div {params.target_flip} {output} -odt float 
        """

rule mask_B1:
    input:
        fmap = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM_norm_brain.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        ImageMath 3 {output} m {input.fmap} {input.mask}
        """
        