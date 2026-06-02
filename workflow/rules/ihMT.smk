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

        
rule denoise_ihmt:
    input:
        raw_img = get_raw_ihmt
    output:
        out=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.nii"),
        noisemap="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_noisemap.nii"
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        dwidenoise {input.raw_img} {output.out} -noise {output.noisemap}
        """


rule degibbs_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise.nii"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii")
    resources:
        mem_mb=1000
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.log"
    shell: #use the Bautista extension of the Kellner protocol because data is 3D not 2D
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrdegibbs -mode 3d {input} {output}
        """


rule moco_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs.nii"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii"
    params:
        ihmt_contrast_type = get_ihmt_contrast_type
    container:
        "docker://rflaherty3636/ihmt_moco:v0.0.1"
    resources: 
        mem_mb=1000
    threads: 4
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.log"
    shell: 
        # The current version of MoCo only allows for 3 contrasts. For 4 contrast case, keep all MTd together.
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        export ANTSPATH="$(which antsRegistration)"
        export ANTSPATH="$(dirname "$ANTSPATH")"
        export FSLDIR="$(dirname "$ANTSPATH")"
        export FSLOUTPUTTYPE='NIFTI_GZ'

        if [ ! -f .snakemake/scripts/ihMT_MoCo.sh ]
        then
            echo "ihMT_MoCo.sh not found! Please sign the license agreement and download the script at https://crmbm.univ-amu.fr/ihmt-moco/, then save the script to .snakemake/scripts/ihMT_MoCo.sh"
        fi

        if [ "{params.ihmt_contrast_type}" == "Frequency Alternated and Cosine Modulated" ]
        then
            imgsize="$(mrinfo -size {input} | awk '{{print $4}}')"
            idx_mts=( $(seq 2 3 $(($imgsize))) )
            idx_mtd_freqalt=( $(seq 3 3 $(($imgsize))) )
            idx_mtd_cosmod=( $(seq 4 3 $(($imgsize))) )
            idx_mtd=( "${{idx_mtd_freqalt[@]}}" "${{idx_mtd_cosmod[@]}}" )
            .snakemake/scripts/ihMT_MoCo.sh -i {input} -o {output} -R 1 -S $idx_mts -D $idx_mtd
        else
            .snakemake/scripts/ihMT_MoCo.sh -i {input} -o {output}
        fi
        """


rule split_contrast_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco.nii"
    output:
        mt0="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir=temp(directory("data/derivatives/{field_strength}/ihmt/acq-{ihmt_params}/sub-{subject}/ses-{session}/preproc/split"))
    params:
        ihmt_contrast_type = get_ihmt_contrast_type,
        mts="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split.log"
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
        mt0="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mt0.nii",
        split_dir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split"
    output:
        sums_means_dir=temp(directory("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/")),
        MTmap=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz")
    params:
        #input depending on contrast type
        mts="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/split/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",  
        #avg depending on contrast type
        mts_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_avg.nii"),
        mtd_cosmod_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_avg.nii"),
        mtd_freqalt_avg=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_avg.nii"),    
        #MTR depending on contrast type
        MTRs="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTRs.nii.gz",
        MTRd_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_MTRd.nii.gz",
        MTRd_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_MTRd.nii.gz", 
        #sum depending on contrast type
        mts_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mts_sum.nii"),
        mtd_cosmod_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_cosmod_sum.nii"),
        mtd_freqalt_sum=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sums_means/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_denoise_degibbs_moco_mtd_freqalt_sum.nii"),
        #ihMTmap depending on contrast type
        ihMTmap_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_ihMTmap.nii.gz",
        ihMTmap_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_ihMTmap.nii.gz",
        #ihMTR depending on contrast type
        ihMTR_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_ihMTR.nii.gz",
        ihMTR_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_ihMTR.nii.gz"      
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihMTmaps.log"
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
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.log"
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
        input_image = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz")
    container:
        "docker://rflaherty3636/ihmt_moco:v0.0.1"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.log"
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
        input_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz")
    container:
        "docker://rflaherty3636/ihmt_moco:v0.0.1"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.log"
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

        
