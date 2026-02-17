import glob

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_raw_ihmt(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_ihmt.nii.gz'))[0]

rule denoise_degibbs_ihmt:
    input:
        check_csa_added_to_meta,
        raw_img = get_raw_ihmt
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_denoise_degibbs.nii.gz"
    threads: 2
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        designer -denoise -shrinkage frob -algorithm jespersen -adaptive_patch -degibbs {input.raw_img} {output}
        """