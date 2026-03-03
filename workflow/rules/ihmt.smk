import glob
import shutil
from pathlib import Path

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_raw_ihmt(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_ihmt.nii.gz'))[0]


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
#         raw_json = Path(input.raw_img).with_suffix("").with_suffix(".json")
#         shutil.copy(raw_json, output.json)
        

# rule denoise_ihmt:
#     input:
#         img="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.nii.gz",
#         json="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.json"
#     output:
#         out="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.gz",
#         noisemap="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_noisemap.nii",
#         #remove dummy bval, bvec, and scratch directory after command has finished
#         bval_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bval"),
#         bvec_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bvec"),
#         bval_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.bval"),
#         bvec_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.bvec"),
#         scratch=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/ihmt_denoise_tmp"))
#     container:
#         "docker://nyudiffusionmri/designer2:v2.0.15"
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
#         designer -denoise -shrinkage frob -algorithm jespersen -pe_dir j -nocleanup -scratch {output.scratch} {input.img} {output.out}
#         #move noisemap out of denoise_tmp and rename for clarity
#         cp {output.scratch}/sigma.nii {output.noisemap}
#         """

rule denoise_ihmt:
    input:
        check_csa_added_to_meta
    params:
        raw_img = get_raw_ihmt
    output:
        out=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.gz"),
        noisemap="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_noisemap.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        dwidenoise {params.raw_img} {output.out} -noise {output.noisemap}
        """


rule degibbs_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs.nii.gz")
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: #use the Bautista extension of the Kellner protocol because data is 3D not 2D
        """
        mrdegibbs -mode 3d {input} {output}
        """


rule moco_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs.nii.gz"
    output:
        preproc="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco.nii"
    container:
        "docker://hugodary/ihmt_proc:latest"
    shell: 
        # -m 1 means use ihMT-MoCo for motion correction (from Soustelle preprint)
        # -c is a comma separated list of desired output images, we chose to only output the motion corrected image without computing any maps
        """
        /opt/ihMT_proc/process_ihMT.sh -m 1 -c ihMT -i {input} -o data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_
        
        #rename preproc image for clarity
        mv data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_ihMT.nii {output.preproc}
        """


#TO DO: make this dependent on sequence type
rule split_contrast_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco.nii"
    output:
        mt0=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mt0.nii"),
        mts=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts.nii"),
        mtd_freqalt=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii"),
        mtd_cosmod=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii")
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        mrconvert {input} {output.mt0} -coord 3 0 -axes 0,1,2
        mrconvert {input} {output.mts} -coord 3 1:3:4
        mrconvert {input} {output.mtd_freqalt} -coord 3 2:3:5
        mrconvert {input} {output.mtd_cosmod} -coord 3 3:3:6
        """
        

rule calculate_ihmt_maps:
    input:
        mt0="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mt0.nii",
        mts="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    output:
        ihMTmap_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz",
        ihMTR_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTR.nii.gz",
        ihMTmap_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_cosmod_ihMTmap.nii.gz",
        ihMTR_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_cosmod_ihMTR.nii.gz",
        mts_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts_sum.nii"),
        mtd_freqalt_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt_sum.nii"),
        mtd_cosmod_sum=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod_sum.nii")
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: 
        """
        mrmath {input.mts} sum {output.mts_sum} -axis 3
        mrmath {input.mtd_freqalt} sum {output.mtd_freqalt_sum} -axis 3
        mrmath {input.mtd_cosmod} sum {output.mtd_cosmod_sum} -axis 3
        
        mrcalc 0 {output.mts_sum} {output.mtd_freqalt_sum} -subtract -max {output.ihMTmap_freqalt}
        mrcalc 1 0 {output.ihMTmap_freqalt} {input.mt0} 0 -max -div nan 0 -replace -max -min {output.ihMTR_freqalt}
        mrcalc 0 {output.mts_sum} {output.mtd_cosmod_sum} -subtract -max {output.ihMTmap_cosmod}
        mrcalc 1 0 {output.ihMTmap_cosmod} {input.mt0} 0 -max -div nan 0 -replace -max -min {output.ihMTR_cosmod}
        """


rule calculate_MTRs_MTRd:
    input:
        mt0="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mt0.nii",
        mts="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    output:
        MTRs="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTRs.nii.gz",
        MTRd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_MTRd.nii.gz",
        MTRd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_cosmod_MTRd.nii.gz",
        mts_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts_avg.nii"),
        mtd_freqalt_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt_avg.nii"),
        mtd_cosmod_avg=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod_avg.nii")
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell:
        """
        mrmath {input.mts} mean {output.mts_avg} -axis 3
        mrmath {input.mtd_freqalt} mean {output.mtd_freqalt_avg} -axis 3
        mrmath {input.mtd_cosmod} mean {output.mtd_cosmod_avg} -axis 3

        mrcalc 1 0 1 {output.mts_avg} {input.mt0} 0 -max -div -subtract -max -min {output.MTRs}
        mrcalc 1 0 1 {output.mtd_freqalt_avg} {input.mt0} 0 -max -div -subtract -max -min {output.MTRd_freqalt}
        mrcalc 1 0 1 {output.mtd_cosmod_avg} {input.mt0} 0 -max -div -subtract -max -min {output.MTRd_cosmod}
        """

#rules for registering to MP2RAGE with ANTs

rule synthstrip_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain.nii.gz"),
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf -g
        else 
            mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        fi
        """

rule DenoiseImage_ihmt:
    input:
        input_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_denoised.nii.gz")
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
        input_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_denoised.nii.gz",
        mask_image="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_denoised_n4.nii.gz"
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
        ref="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz",
        moving="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_denoised_n4.nii.gz",
        ref_mask="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_brain_denoised_n4_registeredtoMP2RAGE.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit_registeredtoIHMT.nii.gz"),
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGE_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Affine[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_IHMTregisteredtoMP2RAGE_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """

rule apply_reg_ihmt_to_MP2RAGE_ants:
    input:
        moving="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz",
        ref="data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGE_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_registeredtoMP2RAGE_ants.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -n Linear -i {input.moving} -r {input.ref} -t {input.reg} -o {output}
        """

#rules for registering to MP2RAGE with easyreg

rule register_ihmt_to_MP2RAGE_easyreg:
    input:
        moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz"
    params:
        moving_seg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_seg.nii.gz",
        ref_seg = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}_t1wUNI_B1Corrected_dicomUnit_seg.nii.gz"
    output:
        moving_reg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_registeredtoMP2RAGE_easyreg.nii.gz",
        fwd_field = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGEmatrix.nii.gz"
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_easyreg --ref {input.ref} --flo {input.moving} --ref_seg {params.ref_seg} --flo_seg {params.moving_seg} --flo_reg {output.moving_reg} --fwd_field {output.fwd_field} --threads 1 --affine_only
        """

#rules for registering to MP2RAGE with synthmorph

rule register_ihmt_to_MP2RAGE_synthmorph:
    input:
        moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGE.lta"
    resources: 
        mem_mb=7000
    container:
        "docker://freesurfer/synthmorph:4"
    shell:
        """
        mri_synthmorph register -m affine -t {output} {input.moving} {input.ref}
        """

rule apply_reg_ihmt_to_MP2RAGE_synthmorph:
    input:
        moving = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz",
        reg = "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_IHMTregisteredtoMP2RAGE.lta"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_ihMTmap_registeredtoMP2RAGE_synthmorph.nii.gz"
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/synthmorph:4"
    shell: #register and reslice to MP2RAGE
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """  
