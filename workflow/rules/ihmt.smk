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

rule degibbs_moco_and_maps_ihmt:
    input:
        "data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs.nii.gz"
    output:
        preproc="data/derivatives/{field_strength}/ihmt/{subject}/{session}/preproc/{subject}_{session}_ihmt_denoise_degibbs_moco.nii",
        ihmtr="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihMTR.nii",
        mtrs="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTRs.nii",
        mtrd="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTRd.nii",
        ihmtrinv="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_ihMTRinv.nii",
        mtrsinv="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTRsinv.nii",
        mtrdinv="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_MTRdinv.nii"
    container:
        "docker://hugodary/ihmt_proc:latest"
    shell: 
        # -m 1 means use ihMT-MoCo for motion correction (from Soustelle preprint)
        # -c is a comma separated list of desired output maps
        """
        /opt/ihMT_proc/process_ihMT.sh -m 1 -c ihMT,ihMTR,MTRs,MTRd,ihMTRinv,MTRsinv,MTRdinv -i {input} -o data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_
        
        #rename preproc image for clarity
        mv data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_ihMT.nii {output.preproc}
        """