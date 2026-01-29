import json
def get_target_flip(wildcards):
    with open(f"data/{wildcards.field_strength}/bids/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp{wildcards.run}_TB1TFL.json", "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10

#TO DO: implement checkpoint for BIDS
wildcard_constraints:
    run=".*" #run can be an empty string

rule smooth_B1:
    input:
        "data/{field_strength}/bids/sub-{subject}/ses-{session}/fmap/sub-{subject}_ses-{session}_acq-famp{run}_TB1TFL.nii.gz",
        "results/add_csa_data_to_meta_{field_strength}.complete"
    output:
        temp("results/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-famp{run}_smooth.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """

rule reslice_B1:
    input:
        b1map = "results/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth.nii.gz",
        ref = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_SoS.nii.gz"
    output:
        temp("results/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1w{acq}MPM{t1flip}.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -r {input.ref} -i {input.b1map} -o {output}
        """

rule normalize_B1_to_target_flip:
    input:
        fmap = "results/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1w{acq}MPM{t1flip}.nii.gz",
        mask = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_brain_mask.nii.gz"
    output:
        "results/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1w{acq}MPM{t1flip}_norm.nii.gz"
    params:
        target_flip = get_target_flip
    conda:
        "../envs/fslmaths.yaml"
    shell:
        """
        fslmaths {input.fmap} -mas {input.mask} -div {params.target_flip} {output} -odt float 
        """