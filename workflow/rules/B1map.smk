import json
import glob
def get_target_flip(wildcards):
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.json'))[-1] #select last run
    with open(json_path, "r") as f:
        b1map_meta = json.load(f)
    return b1map_meta["target_fa_deg"] * 10

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_last_b1map_run(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/fmap/{wildcards.subject}_{wildcards.session}_acq-famp*_TB1TFL.nii.gz'))[-1]

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