import glob

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_inv1(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.mp2rage_params}*_UNIT1.nii.gz'))[0]

def get_mp2rage_qT1_stats(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.stats', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_qR1_stats(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qR1_pksUnit.stats', mp2rage_params=mp2rage_params_list, allow_missing=True)


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
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1.json"
    threads:
        8
    resources: 
        mem_mb=200
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py -b1map_nifti {params.b1map_nifti} -inv1_nifti {params.inv1_nifti} -inv2_nifti {params.inv2_nifti} -unit1_nifti {params.unit1_nifti} -output_json {output} -echo_spacing {params.echo_spacing} -threads {threads} -uncorr_qT1 {params.uncorr_qT1}
        """


rule create_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: 
        mem_mb=3000
    shell:
        """
        /opt/vol_proc/main {input}
        cp "data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/qT1_msUnit.nii.gz" {output}
        """


rule json_for_mp2proc:
    input:
        meta_complete = check_csa_added_to_meta,
        b1map_nifti = "data/derivatives/{field_strength}/B1map/{subject}/{session}/acq-{mp2rage_params}/{subject}_{session}_acq-famp_registeredtoMP2RAGE_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/{subject}/{session}/acq-{mp2rage_params}/{subject}_{session}_acq-famp_registeredtoMP2RAGE_ants.json"
    params:
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
        echo_spacing = config["mp2rage_echo_spacing"]
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/mp2proc.json"
    threads:
        8
    resources: 
        mem_mb=200
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py -b1map_nifti {input.b1map_nifti} -inv1_nifti {params.inv1_nifti} -inv2_nifti {params.inv2_nifti} -unit1_nifti {params.unit1_nifti} -output_json {output} -echo_spacing {params.echo_spacing} -threads {threads}
        """


rule run_mp2proc:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/mp2proc.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: 
        mem_mb=5000
    shell:
        """
        /opt/vol_proc/main {input}
        """


rule synthseg_mp2rage:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz"
    output:
         "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/MP2RAGE_synthseg.nii.gz"
    threads: 8
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthseg --i {input} --o {output} --parc --robust --threads {threads} || mri_synthseg --i {input} --o {output} --parc --robust --threads {threads} --cpu
        """

rule crop_mp2rage_256:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit_cropped.nii.gz"
    resources:
        mem_mb=1000
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        size="$(mrinfo -size {input} | awk '{{print $3}}')"
        start="$((${{size}}-256))"
        mrgrid {input} crop -axis 2 ${{start}}:end {output} -force
        """

rule recon_all:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit_cropped.nii.gz"
    output:
        aparc_mgz="data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
        aparc_nii="data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/orig.mgz",
        orig_nii="data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/orig.nii.gz"
    threads: 8
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mkdir -p $HOME/data/derivatives/{wildcards.field_strength}/freesurfer/
        export SUBJECTS_DIR=$HOME/data/derivatives/{wildcards.field_strength}/freesurfer/
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            export UseGPU=1
        fi
        mri_convert -oni 256 -onj 256 -onk 256 {input} {input}
        recon-all -hires -parallel -3T -i {input} -all -s {wildcards.subject}_{wildcards.session}_acq-{wildcards.mp2rage_params}
        mri_convert {output.aparc_mgz} {output.aparc_nii}
        mri_convert {output.orig_mgz} {output.orig_nii}
        """


rule resize_aparc_to_uncropped:
    input:
        seg = "data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/aparc+aseg_resize.mgz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=1000
    shell:
        """
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license
        size_i="$(mri_head -read {input.ref} | grep -oP '(?<=width = )\d+')"
        size_j="$(mri_head -read {input.ref} | grep -oP '(?<=height = )\d+')"
        size_k="$(mri_head -read {input.ref} | grep -oP '(?<=depth = )\d+')"
        mri_convert -oni $size_i -onj $size_j -onk $size_k {input.seg} {output}
        """


rule mp2rage_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/{subject}_{session}_acq-{mp2rage_params}/mri/aparc+aseg_resize.mgz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.stats",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qR1_pksUnit.stats"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit")
        for map in "${{MP2RAGEmaps[@]}}"; do
            mri_segstats --seg {input} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz --sum data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".stats --excludeid 0
        done
        """  


# rule mp2rage_tsv:
#     input:
#         get_mp2rage_qT1_stats,
#         get_mp2rage_qR1_stats
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/qT1_stats.tsv",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/qR1_stats.tsv"   
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         export FS_LICENSE=.snakemake/scripts/license.txt
#         asegstats2table -i {input}  -t {output} --meas mean --common-segs --no-segno 0
#         """


#rules for registering with ANTs

rule synthstrip_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}.nii.gz"
    output:
        # temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/{qT1}_brain.nii.gz"),
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=8000
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/{qT1}_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

#put MP2RAGE in the space of other contrasts (to avoid interpolation)

rule apply_reg_MP2RAGE_to_ihmt_ants:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE{mp2rage_params}_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/registered_to_ihmt_ants/apply_reg_MP2RAGE_to_{ihmt_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd")
        for map in "${{MTmaps[@]}}"; do
            ref_init="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done

        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_ants/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
            antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r $ref -t [ {input.reg}, 1 ] -o $out
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_MPM_ants:
    input:
        ref="data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        reg="data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/registered_to_{seq}_ants/apply_reg_MP2RAGE_to_{seq}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_ants/"$map"_registeredto{wildcards.seq}.nii.gz"
            antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t [ {input.reg}, 1 ] -o $out
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_ihmt_easyreg:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix_inverse.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_easyreg.done"
    threads: 8
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_easyreg
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_easyreg/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
            mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_MPM_easyreg:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGEmatrix_inverse.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_easyreg.done"
    threads: 8
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_easyreg
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/registered_to_{wildcards.seq}_easyreg/acq-{wildcards.mp2rage_params}/"$map"_registeredto{wildcards.seq}.nii.gz"
            mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_ihmt_synthmorph:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_inverse.lta",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_synthmorph.done"
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_synthmorph
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_synthmorph/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
            mri_synthmorph apply {input[0]} $moving $out
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_MPM_synthmorph:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE_inverse.lta",
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_synthmorph.done"
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_synthmorph
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/{wildcards.subject}/{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_synthmorph/"$map"_registeredto{wildcards.seq}.nii.gz"
            mri_synthmorph apply {input[0]} $moving $out
        done
        touch {output}
        """
