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
        img=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.nii.gz"),
        json=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.json")
    run:
        shutil.copy(input.raw_img, output.img)
        raw_json = Path(input.raw_img).with_suffix("").with_suffix(".json")
        shutil.copy(raw_json, output.json)
        

rule denoise_ihmt:
    input:
        img="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.nii.gz",
        json="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.json"
    output:
        out="data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_denoise.nii.gz",
        bval=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.bval"),
        bvec=temp("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}_raw.bvec"),
        scratch=temp(directory("data/derivatives/{field_strength}/ihmt/{subject}/{session}/{subject}_{session}/denoise_tmp"))
    threads: 8
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    shell: 
        """
        #need to create dummy bvec and bval for designer to work
        vols="$(mrinfo -size {input.img} | awk '{{print $4}}')" #print number of volumes
        vols="$((${{vols}}-1))" #subtract 1, because one of the entries has to be nonzero
        vols_string=$(printf "%${{vols}}s") #function to replicate following string by number of vols
        vols_zeros=${{vols_string// /0 }} #create string with number of 0s equal to number of vols (minus 1)
        echo "${{vols_zeros}}500" > {output.bval} #create dummy bval file with number of entries = number of volumes
        echo -e "${{vols_zeros}}1\n${{vols_zeros}}1\n${{vols_zeros}}1" > {output.bvec} #dummy bvec has to have 3 rows
        #denoise with the jespersen algorithm extension to MPPCA since it is better for multi-contrast data
        designer -denoise -shrinkage frob -algorithm jespersen -adaptive_patch -pe_dir j -nocleanup -scratch {output.scratch} {input.img} {output.out}
        cp data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}/denoise_tmp/sigma.nii data/derivatives/{wildcards.field_strength}/ihmt/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_noisemap.nii
        """