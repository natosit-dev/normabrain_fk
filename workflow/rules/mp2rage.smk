#TO DO: implement synthmorph for registeration
def get_inv1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_UNIT1.nii.gz'))[0]

rule json_for_uncorr_q1:
    input:
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1
    params:
        uncorr_q1 = True
    output:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_q1.json"
    threads:
        8
    script:
        "../scripts/create_json_for_mp2proc.py"

rule create_uncorr_q1:
    input:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_q1.json"
    output:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/qT1_msUnit.nii.gz",
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    shell:
        """
        /opt/vol_proc/main {input}
        cp {output[0]} {output[1]}
        """

rule synthstrip_uncorr_qT1:
    input:
       "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1.nii.gz"
    output:
         "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain.nii.gz",
         "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads:
        4
    shell:
        """
        mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        """

rule N4BiasFieldCorrection_uncorr_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/mp2rage/{subject}/{session}/uncorr_qT1_brain_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        N4BiasFieldCorrection -d 3 -s 1 -v 1 -c [ 50x50x50x50, 0 ] -i {input.input_image} -x {input.mask_image} -o {output}
        """

rule json_for_mp2proc:
    input:
        b1map_nifti = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.json",
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    params:
        uncorr_q1 = False
    output:
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