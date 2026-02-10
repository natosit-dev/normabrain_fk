def get_inv1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_UNIT1.nii.gz'))[0]

rule json_for_mp2proc:
    input:
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    output:
        directory("data/derivatives/{field_strength}/mp2rage/{subject}/{session}/"),
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/mp2proc.json"
    threads:
        8
    script:
        "../scripts/create_json_for_mp2proc.py"

rule run_mp2proc:
    input:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/mp2proc.json"
    output:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/t1wUNI_DEN_dicomUnit.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    shell:
        """
        /opt/vol_proc/main {input}
        """