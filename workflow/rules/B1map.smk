import json
def get_target_flip(wildcards):
    with open(f"data/{wildcards.field_strength}/rawdata/bids/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp_TB1TFL.json", "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10


rule smooth_B1:
    input:
        "data/{field_strength}/rawdata/bids/{subject}/{session}/fmap/{subject}_{session}_acq-famp_TB1TFL.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/B1map/SmoothImage/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        SmoothImage 3 {input} 3x1x1 {output}
        """

rule reslice_B1:
    input:
        b1map = "data/{field_strength}/derivatives/B1map/SmoothImage/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz",
        ref = "data/{field_strength}/derivatives/MPM_preproc/SoS_images_CLI/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-25_mt-off_part-mag_SoS.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/B1map/antsApplyTransforms/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w{acq}MPM.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -r {input.ref} -i {input.b1map} -o {output}
        """

rule normalize_B1_to_target_flip:
    input:
        fmap = "data/{field_strength}/derivatives/B1map/antsApplyTransforms/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w{acq}MPM.nii.gz",
        mask = "data/{field_strength}/derivatives/MPM_preproc/synthstrip/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-25_mt-off_part-mag_SoS_brain_mask.nii.gz"
    output:
        "data/{field_strength}/derivatives/B1map/fslmaths/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w{acq}MPM_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.fmap} -mas {input.mask} -div {params.target_flip} {output} -odt float 
        """