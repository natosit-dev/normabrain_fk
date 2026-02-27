import glob

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_inv1(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_UNIT1.nii.gz'))[0]


rule json_for_uncorr_qT1:
    input:
        meta_complete = check_csa_added_to_meta
    params:
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
        echo_spacing = config["mp2rage_echo_spacing"],
        uncorr_qT1 = True
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.json"
    threads:
        8
    resources: 
        mem_mb=200
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py {params.b1map_nifti} {params.inv1_nifti} {params.inv2_nifti} {params.unit1_nifti} {output} {params.echo_spacing} {threads} {params.uncorr_qT1}
        """


rule create_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: 
        mem_mb=3000
    shell:
        """
        /opt/vol_proc/main {input}
        cp "data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/qT1_msUnit.nii.gz" {output}
        """


rule json_for_mp2proc:
    input:
        meta_complete = check_csa_added_to_meta,
        b1map_nifti = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredtoMP2RAGE.json"
    params:
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
        echo_spacing = config["mp2rage_echo_spacing"],
        uncorr_qT1 = False
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/mp2proc.json"
    threads:
        8
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    #script:
        #"../scripts/create_json_for_mp2proc.py"
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py {input.b1map_nifti} {params.inv1_nifti} {params.inv2_nifti} {params.unit1_nifti} {output} {params.echo_spacing} {threads} {params.uncorr_qT1}
        """


rule run_mp2proc:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/mp2proc.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        /opt/vol_proc/main {input}
        """


#rules for registering with ANTs

rule synthstrip_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain.nii.gz"),
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 2
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf -g
        else 
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        fi
        """


rule DenoiseImage_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

rule synthstrip_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain.nii.gz"),
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 2
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf -g
        else 
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        fi
        """


rule DenoiseImage_uncorr_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection_uncorr_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """