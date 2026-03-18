import json
import glob
import shutil
from pathlib import Path

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_raw_ihmt(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}*_ihmt.nii.gz'))[0] #get first run

def get_ihmt_contrast_type(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}*_ihmt.json'))[0]
    with open(json_path, "r") as f:
        meta = json.load(f)
        ihmt_contrast_type = meta["ContrastType"]
    return ihmt_contrast_type


# rule copy_raw_ihmt_data:
#     #img, json, bvec, and bval need to have the same basename for designer to work
#     #we don't want to save dummy bvec and bval to rawdata so instead we will copy img and json
#     input:
#         check_csa_added_to_meta
#     params:
#         raw_img = get_raw_ihmt
#     output:
#         img=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.nii.gz"),
#         json=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.json")
#     run:
#         shutil.copy(params.raw_img, output.img)
#         raw_json = Path(params.raw_img).with_suffix("").with_suffix(".json")
#         shutil.copy(raw_json, output.json)
        

# rule denoise_ihmt:
#     input:
#         img="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.nii.gz",
#         json="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.json"
#     output:
#         out=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii"),
#         noisemap="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_noisemap.nii",
#         #remove dummy bval, bvec, and scratch directory after command has finished
#         bval_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bval"),
#         bvec_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bvec"),
#         bval_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.bval"),
#         bvec_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.bvec"),
#         scratch=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/ihmt_denoise_tmp"))
#     container:
#         "docker://nyudiffusionmri/designer2:v2.0.15"
#     threads: 8
    # resources:
    #     mem_mb=1000
#     shell: #turn off adaptive_patch for now, it takes 12 minutes per subject
#         """
#         #need to create dummy bvec and bval for designer to work
#         vols="$(mrinfo -size {input.img} | awk '{{print $4}}')" #print number of volumes
#         vols="$((${{vols}}-1))" #subtract 1, because one of the entries has to be nonzero
#         vols_string=$(printf "%${{vols}}s") #function to replicate following string by number of vols
#         vols_zeros=${{vols_string// /0 }} #create string with number of 0s equal to number of vols (minus 1)
#         echo "${{vols_zeros}}500" > {output.bval_raw} #create dummy bval file with number of entries = number of volumes
#         echo -e "${{vols_zeros}}1\n${{vols_zeros}}1\n${{vols_zeros}}1" > {output.bvec_raw} #dummy bvec has to have 3 rows

#         #denoise with the jespersen algorithm extension to MPPCA since it is better for multi-contrast data
#         #pe_dir is not relevant for denoise but designer throws an error if it is not set, set it to j for now
#         designer -denoise -algorithm jespersen -pe_dir j -nocleanup -nthreads {threads} -scratch {output.scratch} {input.img} {output.out}
#         #move noisemap out of denoise_tmp and rename for clarity
#         cp {output.scratch}/sigma.nii {output.noisemap}
#         """

rule denoise_ihmt:
    input:
        check_csa_added_to_meta
    params:
        raw_img = get_raw_ihmt
    output:
        out=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise.nii"),
        noisemap="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_noisemap.nii"
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        dwidenoise {params.raw_img} {output.out} -noise {output.noisemap}
        """


rule degibbs_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise.nii"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii")
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: #use the Bautista extension of the Kellner protocol because data is 3D not 2D
        """
        mrdegibbs -mode 3d {input} {output}
        """


rule moco_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii"
    output:
        preproc="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii"
    container:
        "docker://hugodary/ihmt_proc:latest"
    shell: 
        # -m 1 means use ihMT-MoCo for motion correction (from Soustelle preprint)
        # -c is a comma separated list of desired output images, we chose to only output the motion corrected image without computing any maps
        """
        /opt/ihMT_proc/process_ihMT.sh -m 1 -c ihMT -i {input} -o data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/acq-{wildcards.ihmt_params}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_
        
        #rename preproc image for clarity
        mv data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/acq-{wildcards.ihmt_params}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_ihMT.nii {output.preproc}
        rm -rf data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/acq-{wildcards.ihmt_params}
        """


rule split_contrast_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii",
        check_csa_added_to_meta
    output:
        mt0="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}"))
    params:
        ihmt_contrast_type = get_ihmt_contrast_type,
        mts="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_basic="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_basic.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        mrconvert {input[0]} {output.mt0} -coord 3 0 -axes 0,1,2 -force

        if [ "{params.ihmt_contrast_type}" == "Frequency Alternated and Cosine Modulated" ]
        then
            mrconvert {input[0]} {params.mts} -coord 3 1:3:end -force
            mrconvert {input[0]} {params.mtd_freqalt} -coord 3 2:3:end -force
            mrconvert {input[0]} {params.mtd_cosmod} -coord 3 3:3:end -force
        
        elif [ "{params.ihmt_contrast_type}" == "Basic" ]
        then
            mrconvert {input[0]} {params.mts} -coord 3 1:2:end -force
            mrconvert {input[0]} {params.mtd_basic} -coord 3 2:2:end -force
        
        elif [ "{params.ihmt_contrast_type}" == "Frequency Alternated" ]
        then
            mrconvert {input[0]} {params.mts} -coord 3 1:2:end -force
            mrconvert {input[0]} {params.mtd_freqalt} -coord 3 2:2:end -force

        elif [ "{params.ihmt_contrast_type}" == "Cosine Modulated" ]
        then
            mrconvert {input[0]} {params.mts} -coord 3 1:2:end -force
            mrconvert {input[0]} {params.mtd_cosmod} -coord 3 2:2:end -force

        elif [ "{params.ihmt_contrast_type}" == "BandPass (no single)" ]
        then
            mrconvert {input[0]} {params.mtd_freqalt} -coord 3 1:2:end -force
            mrconvert {input[0]} {params.mtd_cosmod} -coord 3 2:2:end -force
        fi
        """
        

rule calculate_ihmt_maps:
    input:
        mt0="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}"
    output:
        sums_means_dir=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/")),
        MTmap=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap.nii.gz")
    params:
        #input depending on contrast type
        mts="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_basic="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_basic.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/split_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",  
        #avg depending on contrast type
        mts_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_avg.nii"),
        mtd_basic_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_basic_avg.nii"),
        mtd_cosmod_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_avg.nii"),
        mtd_freqalt_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_avg.nii"),    
        #MTR depending on contrast type
        MTRs="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTRs.nii.gz",
        MTRd_basic="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_basic_MTRd.nii.gz",
        MTRd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_cosmod_MTRd.nii.gz",
        MTRd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_freqalt_MTRd.nii.gz", 
        #sum depending on contrast type
        mts_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_sum.nii"),
        mtd_basic_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_basic_sum.nii"),
        mtd_cosmod_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_sum.nii"),
        mtd_freqalt_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/sums_means_acq-{ihmt_params}/{subject}_{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_sum.nii"),
        #ihMTmap depending on contrast type
        ihMTmap_basic="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_basic_ihMTmap.nii.gz",
        ihMTmap_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_cosmod_ihMTmap.nii.gz",
        ihMTmap_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_freqalt_ihMTmap.nii.gz",
        #ihMTR depending on contrast type
        ihMTR_basic="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_basic_ihMTR.nii.gz",
        ihMTR_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_cosmod_ihMTR.nii.gz",
        ihMTR_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_freqalt_ihMTR.nii.gz"      
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: 
        """
        mkdir -p {output.sums_means_dir}
        if [ -f {params.mts} ]
        then
            mrmath {params.mts} mean {params.mts_avg} -axis 3 -force
            mrcalc 1 0 1 {params.mts_avg} {input.mt0} 0 -max -div nan 0 -replace -subtract -max -min {params.MTRs} -force
            mrmath {params.mts} sum {params.mts_sum} -axis 3 -force
            cp {params.MTRs} {output.MTmap}
        fi

        if [ -f {params.mtd_basic} ]
        then
            mrmath {params.mtd_basic} mean {params.mtd_basic_avg} -axis 3 -force
            mrcalc 1 0 1 {params.mtd_basic_avg} {input.mt0} 0 -max -div nan 0 -replace -subtract -max -min {params.MTRd_basic} -force
            cp {params.MTRd_basic} {output.MTmap}
        fi

        if [ -f {params.mtd_freqalt} ]
        then
            mrmath {params.mtd_freqalt} mean {params.mtd_freqalt_avg} -axis 3 -force
            mrcalc 1 0 1 {params.mtd_freqalt_avg} {input.mt0} 0 -max -div nan 0 -replace -subtract -max -min {params.MTRd_freqalt} -force
            cp {params.MTRd_freqalt} {output.MTmap}
        fi

        if [ -f {params.mtd_cosmod} ]
        then
            mrmath {params.mtd_cosmod} mean {params.mtd_cosmod_avg} -axis 3 -force
            mrcalc 1 0 1 {params.mtd_cosmod_avg} {input.mt0} 0 -max -div nan 0 -replace -subtract -max -min {params.MTRd_cosmod} -force
            cp {params.MTRd_cosmod} {output.MTmap}
        fi

        if [ -f {params.mts} ] && [ -f {params.mtd_basic} ]
        then
            mrmath {params.mtd_basic} sum {params.mtd_basic_sum} -axis 3 -force
            mrcalc 0 {params.mts_sum} {params.mtd_basic_sum} -subtract -max {params.ihMTmap_basic} -force
            mrcalc 1 0 {params.ihMTmap_basic} {input.mt0} 0 -max -div nan 0 -replace -max -min {params.ihMTR_basic} -force
            cp {params.ihMTmap_basic} {output.MTmap}
        fi

        if [ -f {params.mts} ] && [ -f {params.mtd_freqalt} ]
        then
            mrmath {params.mtd_freqalt} sum {params.mtd_freqalt_sum} -axis 3 -force
            mrcalc 0 {params.mts_sum} {params.mtd_freqalt_sum} -subtract -max {params.ihMTmap_freqalt} -force
            mrcalc 1 0 {params.ihMTmap_freqalt} {input.mt0} 0 -max -div nan 0 -replace -max -min {params.ihMTR_freqalt} -force
            cp {params.ihMTmap_freqalt} {output.MTmap}
        fi

        if [ -f {params.mts} ] && [ -f {params.mtd_cosmod} ]
        then
            mrmath {params.mtd_cosmod} sum {params.mtd_cosmod_sum} -axis 3 -force
            mrcalc 0 {params.mts_sum} {params.mtd_cosmod_sum} -subtract -max {params.ihMTmap_cosmod} -force
            mrcalc 1 0 {params.ihMTmap_cosmod} {input.mt0} 0 -max -div nan 0 -replace -max -min {params.ihMTR_cosmod} -force
            cp {params.ihMTmap_cosmod} {output.MTmap}
        fi
        """


#rules for registering to MP2RAGE with ANTs

rule synthstrip_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap.nii.gz"
    output:
        # temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTmap_brain.nii.gz"),
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_ihmt:
    input:
        input_image = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """

rule N4BiasFieldCorrection_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

rule register_ihmt_to_MP2RAGE_ants:
    input:
        ref="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_DEN_dicomUnit.nii.gz",
        moving="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
        ref_mask="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4_registeredtoMP2RAGE.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit_registeredtoIHMT{ihmt_params}.nii.gz"),
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Affine[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_IHMTregisteredtoMP2RAGE_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """

rule apply_reg_ihmt_to_MP2RAGE_ants:
    input:
        # moving="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTmap.nii.gz",
        ref="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_DEN_dicomUnit.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_apply_reg_ihmt_to_MP2RAGE_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MTmaps=("MTRs" "basic_MTRd" "cosmod_MTRd" "freqalt_MTRd" "basic_ihMTmap" "cosmod_ihMTmap" "freqalt_ihMTmap" "basic_ihMTR" "cosmod_ihMTR" "freqalt_ihMTR")
        mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_ants
        for map in "${{MTmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_ants/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t {input.reg} -o $out
            fi
        done
        touch {output}
        """

#rules for registering to MP2RAGE with easyreg

rule register_ihmt_to_MP2RAGE_easyreg:
    input:
        moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_DEN_dicomUnit.nii.gz",
        ref_seg = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/MP2RAGE_synthseg.nii.gz"
    params:
        moving_seg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_ihmt_seg.nii.gz"
    output:
        # moving_reg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTmap_registeredtoMP2RAGE_easyreg.nii.gz",
        fwd_field = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix.nii.gz",
        bak_field = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix_inverse.nii.gz"
    resources:
        mem_mb=15000
    threads: 8
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_easyreg --ref {input.ref} --flo {input.moving} --ref_seg {input.ref_seg} --flo_seg {params.moving_seg} --fwd_field {output.fwd_field} --bak_field {output.bak_field} --threads {threads} --affine_only
        """


rule apply_reg_ihmt_to_MP2RAGE_easyreg:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_apply_reg_ihmt_to_MP2RAGE_easyreg.done"
    threads: 8
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        MTmaps=("MTRs" "basic_MTRd" "cosmod_MTRd" "freqalt_MTRd" "basic_ihMTmap" "cosmod_ihMTmap" "freqalt_ihMTmap" "basic_ihMTR" "cosmod_ihMTR" "freqalt_ihMTR")
        mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_easyreg
        for map in "${{MTmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_easyreg/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE.nii.gz"
            if [ -f $moving ]; then
                mri_easywarp --i $moving --o $out --field {input} --threads {threads}
            fi
        done
        touch {output}
        """

#rules for registering to MP2RAGE with synthmorph

rule register_ihmt_to_MP2RAGE_synthmorph:
    input:
        moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_MTmap.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_DEN_dicomUnit.nii.gz"
    output:
        reg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE.lta",
        reg_inv = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_inverse.lta"
    resources: 
        mem_mb=7000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref}
        lta_convert --inlta {output.reg} --outlta {output.reg_inv} --invert
        """

rule apply_reg_ihmt_to_MP2RAGE_synthmorph:
    input:
        # moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTmap.nii.gz",
        # ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz",
        reg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGE.lta"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_apply_reg_ihmt_to_MP2RAGE_synthmorph.done"
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: #register and reslice to MP2RAGE
        """
        MTmaps=("MTRs" "basic_MTRd" "cosmod_MTRd" "freqalt_MTRd" "basic_ihMTmap" "cosmod_ihMTmap" "freqalt_ihMTmap" "basic_ihMTR" "cosmod_ihMTR" "freqalt_ihMTR")
        mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_synthmorph
        for map in "${{MTmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_synthmorph/{wildcards.subject}_{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE.nii.gz"
            if [ -f $moving ]; then
                mri_synthmorph apply {input.reg} $moving $out
            fi
        done
        touch {output}
        
        """  
