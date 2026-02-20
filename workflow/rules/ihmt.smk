import glob
import shutil
from pathlib import Path

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_raw_ihmt(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_ihmt.nii.gz'))[0]


rule copy_raw_ihmt_data:
    #img, json, bvec, and bval need to have the same basename for designer to work
    #we don't want to save dummy bvec and bval to rawdata so instead we will copy img and json
    input:
        check_csa_added_to_meta,
        raw_img = get_raw_ihmt
    output:
        img=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.nii.gz"),
        json=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.json")
    run:
        shutil.copy(input.raw_img, output.img)
        raw_json = Path(input.raw_img).with_suffix("").with_suffix(".json")
        shutil.copy(raw_json, output.json)
        

rule denoise_ihmt:
    input:
        img="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.nii.gz",
        json="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.json"
    output:
        out="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.gz",
        noisemap="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_noisemap.nii",
        #remove dummy bval, bvec, and scratch directory after command has finished
        bval_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bval"),
        bvec_raw=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihmt_raw.bvec"),
        bval_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.bval"),
        bvec_denoise=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.bvec"),
        scratch=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/ihmt_denoise_tmp"))
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: 
        """
        #need to create dummy bvec and bval for designer to work
        vols="$(mrinfo -size {input.img} | awk '{{print $4}}')" #print number of volumes
        vols="$((${{vols}}-1))" #subtract 1, because one of the entries has to be nonzero
        vols_string=$(printf "%${{vols}}s") #function to replicate following string by number of vols
        vols_zeros=${{vols_string// /0 }} #create string with number of 0s equal to number of vols (minus 1)
        echo "${{vols_zeros}}500" > {output.bval_raw} #create dummy bval file with number of entries = number of volumes
        echo -e "${{vols_zeros}}1\n${{vols_zeros}}1\n${{vols_zeros}}1" > {output.bvec_raw} #dummy bvec has to have 3 rows

        #denoise with the jespersen algorithm extension to MPPCA since it is better for multi-contrast data
        #pe_dir is not relevant for denoise but designer throws an error if it is not set, set it to j for now
        designer -denoise -shrinkage frob -algorithm jespersen -adaptive_patch -pe_dir j -nocleanup -scratch {output.scratch} {input.img} {output.out}
        #move noisemap out of denoise_tmp and rename for clarity
        cp {output.scratch}/sigma.nii {output.noisemap}
        """


rule degibbs_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise.nii.gz"
    output:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs.nii.gz"
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
        # -c is a comma separated list of desired output maps
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
        mrcalc 0 {output.ihMTmap_freqalt} {input.mt0} 0 -max -div -max {output.ihMTR_freqalt}
        mrcalc 0 {output.mts_sum} {output.mtd_cosmod_sum} -subtract -max {output.ihMTmap_cosmod}
        mrcalc 0 {output.ihMTmap_cosmod} {input.mt0} 0 -max -div -max {output.ihMTR_cosmod}
        """


rule calculate_MTRs_MTRd:
    input:
        mt0="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mt0.nii",
        mts="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mts.nii",
        mtd_freqalt="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_freqalt.nii",
        mtd_cosmod="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco_mtd_cosmod.nii"
    output:
        MTRs="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_freqalt_MTRs.nii.gz",
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

        mrcalc 0 1 {output.mts_avg} {input.mt0} 0 -max -div -subtract -max {output.MTRs}
        mrcalc 0 1 {output.mtd_freqalt_avg} {input.mt0} 0 -max -div -subtract -max {output.MTRd_freqalt}
        mrcalc 0 1 {output.mtd_cosmod_avg} {input.mt0} 0 -max -div -subtract -max {output.MTRd_cosmod}
        """