#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk
import glob
from pathlib import Path
from bids import BIDSLayout
from lxml import etree
import re
from collections import Counter

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["qMT_contrasts"]]),
    seq = config["qMT_sequence"],
    part = 'mag|phase'


def mp2rage_echo_spacing(wildcards):
    protocol_name = wildcards.subject.replace("sub-", "").lstrip("0123456789.-")
    protocol_name_pattern = "*" + protocol_name + "*/*.xml"
    search_path = Path(config["protocol_path"]) / wildcards.field_strength
    xml_path_list = sorted(search_path.rglob(protocol_name_pattern, case_sensitive=False))
    if len(xml_path_list) > 0:
        xml_path = xml_path_list[0]
        xml_tree = etree.parse(xml_path)
        xml_root = xml_tree.getroot()
        echo_spacing_unit = xml_root.xpath(".//SubStep[ProtHeaderInfo[HeaderProtPath[contains(text(), 'mp2r')]]]/Card/ProtParameter[Label[contains(text(), 'Echo Spacing')]]/ValueAndUnit")[0].text
        numeric_const_pattern = r'[-+]? (?: (?: \d* \. \d+ ) | (?: \d+ \.? ) )(?: [Ee] [+-]? \d+ ) ?'
        rx = re.compile(numeric_const_pattern, re.VERBOSE)
        echo_spacing = float(rx.findall( echo_spacing_unit )[0])
    else:
        echo_spacing = 7.4
    return echo_spacing

def get_inv1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_UNIT1.nii.gz'))[0]

def get_preproc_uniden_list(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_brainmask_list(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_acq_array(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    mp2rage_params_array = " ".join(mp2rage_params_list)
    return mp2rage_params_array

def seg_first_acq_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz', mp2rage_params=first_acq, allow_missing=True)

def resliced_seg_first_acq_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz", mp2rage_params=first_acq, allow_missing=True)

def mp2rage_statslist(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
            for acq in acqlist:
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/MP2RAGE_{mp2rage_map}.stats")
    return sorted(statslist)

def freesurfer_subjectlist_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
            for acq in acqlist:
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray


rule json_for_uncorr_qT1:
    input:
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    params:
        echo_spacing = mp2rage_echo_spacing,
        uncorr_qT1 = True
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.json"
    threads:
        8
    resources: 
        mem_mb=200
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python3 workflow/scripts/create_json_for_mp2proc.py \
        -b1map_nifti {input.b1map_nifti} \
        -inv1_nifti {input.inv1_nifti} \
        -inv2_nifti {input.inv2_nifti} \
        -unit1_nifti {input.unit1_nifti} \
        -output_json {output} \
        -echo_spacing {params.echo_spacing} \
        -threads {threads} \
        -uncorr_qT1 {params.uncorr_qT1}
        """


rule create_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.json"
    params:
        qT1="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources:
        mem_mb=3000
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        /opt/vol_proc/main {input}
        cp {params.qT1} {output}
        """


rule json_for_mp2proc:
    input:
        b1map_nifti = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.json",
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1
    params:
        echo_spacing = mp2rage_echo_spacing
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.json"
    threads:
        8
    resources: 
        mem_mb=200
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc_json.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python3 workflow/scripts/create_json_for_mp2proc.py \
        -b1map_nifti {input.b1map_nifti} \
        -inv1_nifti {input.inv1_nifti} \
        -inv2_nifti {input.inv2_nifti} \
        -unit1_nifti {input.unit1_nifti} \
        -output_json {output} \
        -echo_spacing {params.echo_spacing} \
        -threads {threads}
        """


rule run_mp2proc:
    input:
        mp2proc_json="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.json",
        b1map_nifti = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.json"
    output:
        b1="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_smooth_norm.nii.gz",
        t1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr.nii.gz",
        r1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_R1map_b1corr.nii.gz",
        uniden_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr.nii.gz",
        uniden_uncorr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
        uni_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNI_b1corr.nii.gz"
    params:
        b1="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/b1_processed_relativeUnit_perThousand.nii.gz",
        t1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        r1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qR1_pksUnit.nii.gz",
        uniden_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz",
        uniden_uncorr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz",
        uni_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_dicomUnit.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: 
        mem_mb=5000
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        /opt/vol_proc/main {input.mp2proc_json}

        mv {params.b1} {output.b1}
        mv {params.t1map} {output.t1map}
        mv {params.r1map} {output.r1map}
        mv {params.uniden_corr} {output.uniden_corr}
        mv {params.uniden_uncorr} {output.uniden_uncorr}
        mv {params.uni_corr} {output.uni_corr}
        """


rule synthseg_mp2rage:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr.nii.gz"
    output:
         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/MP2RAGE_synthseg.nii.gz"
    threads: 8
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/MP2RAGE_synthseg.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        #try GPU, then run CPU if it fails
        mri_synthseg --i {input} --o {output} --parc --robust --threads {threads} || \
        mri_synthseg --i {input} --o {output} --parc --robust --threads {threads} --cpu
        """


rule register_mp2rage_acqs:
    input:
        img_list=get_preproc_uniden_list,
        mask_list=get_mp2rage_brainmask_list
    params:
        acq_array=get_mp2rage_acq_array,
        regdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/",
        subject="sub-{subject}_ses-{session}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 4
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        img_array=( {input.img_list} )
        mask_array=( {input.mask_list} )
        acq_array=( {params.acq_array} )

        if [ "${{#img_array[@]}}" -gt 1 ]; then
            first_acq="${{acq_array[0]}}"
            first_img="${{img_array[0]}}"
            first_mask="${{mask_array[0]}}"
            img_array_clipped=("${{img_array[@]:1}}")
            
            i=0
            for img in "${{img_array_clipped[@]}}"; do
                i=$((i+1))
                acq="${{acq_array[$i]}}"
                mask="${{mask_array[$i]}}"
                
                mkdir -p {params.regdir}/acq-$acq/coreg/

                antsRegistration \
                --random-seed 1 \
                --dimensionality 3 \
                --verbose 1 \
                --convergence [ 1000x500x250x100, 1e-7, 100 ] \
                --shrink-factors 8x4x2x1 \
                --smoothing-sigmas 4x2x1x0vox \
                --transform Rigid[0.1] \
                --metric MI[ ${{first_img}}, ${{img}}, 1, 32 ] \
                -o {params.regdir}/acq-$acq/coreg/{params.subject}_acq-${{acq}}_reg2${{first_acq}}_ \
                -x [ ${{first_mask}}, ${{mask}} ] 
            done
        fi
        touch {output}
        """


rule apply_reg_first_mp2rage_acq:
    input:
        reg_done="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done",
        moving="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}.nii.gz"
    params:
        acq_array=get_mp2rage_acq_array,
        sessiondir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        acq_array=( {params.acq_array} )
        first_acq="${{acq_array[0]}}"
        if [ -f {params.sessiondir}/acq-{wildcards.mp2rage_params}/coreg/{params.subject}_reg2${{first_acq}}_0GenericAffine.mat ]; then    
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            --reference-image {params.sessiondir}/acq-$first_acq/sub-{wildcards.subject}_ses-{wildcards.session}_acq-${{first_acq}}_{wildcards.mp2rage_map}.nii.gz \
            --transform {params.sessiondir}/acq-{wildcards.mp2rage_params}/coreg/{params.subject}_reg2${{first_acq}}_0GenericAffine.mat \
            -o {output}
        else
            cp {input.moving} {output}
        fi
        """


rule crop_mp2rage_256:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_cropped.nii.gz"
    resources:
        mem_mb=1000
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_cropped.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        #crop neck
        size_2="$(mrinfo -size {input} | awk '{{print $3}}')"
        start_2="$((${{size_2}}-256))"
        mrgrid {input} crop -axis 2 ${{start_2}}:end {output} -force 

        #crop nose
        mrgrid {output} crop -axis 1 0:255 {output} -force 

        #pad ears
        size_0="$(mrinfo -size {input} | awk '{{print $1}}')"
        pad_size_0="$(((256-${{size_0}})/2))"
        mrgrid {output} pad -axis 0 ${{pad_size_0}},${{pad_size_0}} {output} -force 
        """


rule recon_all:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_cropped.nii.gz"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        aparc_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
        aparc_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        orig_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.nii.gz"
    threads: 8
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/recon-all.log"
    shell:
        """
        #create and set SUBJECTS_DIR
        mkdir -p $HOME/{params.subjects_dir}
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #set up GPU
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            export UseGPU=1
        fi

        #remove old recon-all folder
        rm -rf $SUBJECTS_DIR/{params.subject}

        #run recon-all
        recon-all -hires -parallel -3T -i {input} -all -s {params.subject}

        #convert aparc and orig to nii for easier QC
        mri_convert {output.aparc_mgz} {output.aparc_nii}
        mri_convert {output.orig_mgz} {output.orig_nii}

        #copy log to logs folder
        cp $SUBJECTS_DIR/{params.subject}/scripts/recon-all.log {log}
        """


rule reslice_segmentation:
    input:
        seg=seg_first_acq_mp2rage,
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_coreg.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz"
    resources:
        mem_mb=1000
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/aparc+aseg_resliced.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrgrid {input.seg} regrid -template {input.ref} -strides {input.ref} -interp nearest {output} -force
        """
    

rule mp2rage_stats:
    input:
        seg="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz",
        mp2rage_map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/stats/MP2RAGE_{mp2rage_map}.stats"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/MP2RAGE_{mp2rage_map}_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license
        
        mri_segstats --seg {input.seg} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i {input.mp2rage_map} --sum {output} --excludeid 0
        """  


rule mp2rage_tsv:
    input:
        mp2rage_statslist
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subjects_list=freesurfer_subjectlist_mp2rage,
        statsfile="MP2RAGE_{mp2rage_map}.stats"
    output:
        "data/derivatives/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats.tsv"  
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats_tsv.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        asegstats2table --subjects {params.subjects_list} --statsfile {params.statsfile} -t {output} --meas mean --common-segs --no-segno 0
        """


#rules for registering with ANTs

rule synthstrip_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=8000
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_mask.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        DenoiseImage \
        --image-dimensionality 3 \
        --noise-model Rician \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """


rule N4BiasFieldCorrection_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised_n4.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        
        N4BiasFieldCorrection \
        --image-dimensionality 3 \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """

