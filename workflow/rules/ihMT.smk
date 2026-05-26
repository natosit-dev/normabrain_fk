#requires BIDS data at data/rawdata/bids/{field_strength}
import json
import glob
import shutil
from pathlib import Path


def get_raw_ihmt(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}*_ihmt.nii.gz'))[0] #get first run

def get_ihmt_contrast_type(wildcards):
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}*_ihmt.json'))[0]
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
#         img=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.nii.gz"),
#         json=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.json")
#     run:
#         shutil.copy(params.raw_img, output.img)
#         raw_json = Path(params.raw_img).with_suffix("").with_suffix(".json")
#         shutil.copy(raw_json, output.json)
        

# rule denoise_ihmt:
#     input:
#         img="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.nii.gz",
#         json="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.json"
#     output:
#         out=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_ihmt_denoise.nii"),
#         noisemap="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_ihmt_noisemap.nii",
#         #remove dummy bval, bvec, and scratch directory after command has finished
#         bval_raw=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.bval"),
#         bvec_raw=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_ihmt_raw.bvec"),
#         bval_denoise=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_ihmt_denoise.bval"),
#         bvec_denoise=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_ihmt_denoise.bvec"),
#         scratch=temp(directory("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/ihmt_denoise_tmp"))
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
        raw_img = get_raw_ihmt
    output:
        out=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.nii"),
        noisemap="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_noisemap.nii"
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        dwidenoise {input.raw_img} {output.out} -noise {output.noisemap}
        """


rule degibbs_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.nii"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii")
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.log"
    shell: #use the Bautista extension of the Kellner protocol because data is 3D not 2D
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrdegibbs -mode 3d {input} {output}
        """


rule moco_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii"
    output:
        preproc="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii"
    params:
        outprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_",
        outtmp="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}"
    container:
        "docker://hugodary/ihmt_proc:latest"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.log"
    shell: 
        # -m 1 means use ihMT-MoCo for motion correction (from Soustelle preprint)
        # -c is a comma separated list of desired output images, we chose to only output the motion corrected image without computing any maps
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        /opt/ihMT_proc/process_ihMT.sh -m 1 -c ihMT -i {input} -o {params.outprefix}
        
        #rename preproc image for clarity
        mv {params.outprefix}ihMT.nii {output.preproc}
        rm -rf {params.outtmp}
        """


rule split_contrast_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii"
    output:
        mt0="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir=temp(directory("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}"))
    params:
        ihmt_contrast_type = get_ihmt_contrast_type,
        mts="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        mrconvert {input} {output.mt0} -coord 3 0 -axes 0,1,2 -force

        if [ "{params.ihmt_contrast_type}" == "Frequency Alternated and Cosine Modulated" ]
        then
            mrconvert {input} {params.mts} -coord 3 1:3:end -force
            mrconvert {input} {params.mtd_freqalt} -coord 3 2:3:end -force
            mrconvert {input} {params.mtd_cosmod} -coord 3 3:3:end -force
        
        elif [ "{params.ihmt_contrast_type}" == "Frequency Alternated" ]
        then
            mrconvert {input} {params.mts} -coord 3 1:2:end -force
            mrconvert {input} {params.mtd_freqalt} -coord 3 2:2:end -force

        elif [ "{params.ihmt_contrast_type}" == "Cosine Modulated" ]
        then
            mrconvert {input} {params.mts} -coord 3 1:2:end -force
            mrconvert {input} {params.mtd_cosmod} -coord 3 2:2:end -force

        elif [ "{params.ihmt_contrast_type}" == "BandPass (no single)" ]
        then
            mrconvert {input} {params.mtd_freqalt} -coord 3 1:2:end -force
            mrconvert {input} {params.mtd_cosmod} -coord 3 2:2:end -force
        fi
        """
        

rule calculate_ihmt_maps:
    input:
        mt0="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}"
    output:
        sums_means_dir=temp(directory("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/")),
        MTmap=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz")
    params:
        #input depending on contrast type
        mts="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/preproc/split_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",  
        #avg depending on contrast type
        mts_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_avg.nii"),
        mtd_cosmod_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_avg.nii"),
        mtd_freqalt_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_avg.nii"),    
        #MTR depending on contrast type
        MTRs="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTRs.nii.gz",
        MTRd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_MTRd.nii.gz",
        MTRd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_MTRd.nii.gz", 
        #sum depending on contrast type
        mts_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_sum.nii"),
        mtd_cosmod_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_sum.nii"),
        mtd_freqalt_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sums_means_acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_sum.nii"),
        #ihMTmap depending on contrast type
        ihMTmap_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_ihMTmap.nii.gz",
        ihMTmap_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_ihMTmap.nii.gz",
        #ihMTR depending on contrast type
        ihMTR_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_ihMTR.nii.gz",
        ihMTR_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_ihMTR.nii.gz"      
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihMTmaps.log"
    shell: 
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        mkdir -p {output.sums_means_dir}
        if [ -f {params.mts} ]
        then
            mrmath {params.mts} mean {params.mts_avg} -axis 3 -force
            mrcalc 1 0 1 {params.mts_avg} {input.mt0} 0 -max -div nan 0 -replace -subtract -max -min {params.MTRs} -force
            mrmath {params.mts} sum {params.mts_sum} -axis 3 -force
            cp {params.MTRs} {output.MTmap}
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


rule synthstrip_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_ihmt:
    input:
        input_image = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        DenoiseImage \
        --image-dimensionality 3 \
        --noise-model "Rician" \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """


rule N4BiasFieldCorrection_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        
        N4BiasFieldCorrection \
        --image-dimensionality 3 \
        --shrink-factor 1 \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """

        
