#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk
import glob
from pathlib import Path
from bids import BIDSLayout
from lxml import etree
import re
from collections import Counter

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"],
    part = 'mag|phase'

# def check_csa_added_to_meta(wildcards):
#     return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

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
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-1_MP2RAGE.nii.gz'))[0]

def get_inv2(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_inv-2_MP2RAGE.nii.gz'))[0]

def get_unit1(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}*_UNIT1.nii.gz'))[0]

def get_uniden(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_brain_masks(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_acqs(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    mp2rage_params_array = " ".join(mp2rage_params_list)
    return mp2rage_params_array

def seg_first_acq_mp2rage(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/MP2RAGE_synthseg.nii.gz', mp2rage_params=first_acq, allow_missing=True)

def resliced_seg_first_acq_mp2rage(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz", mp2rage_params=first_acq, allow_missing=True)

def mp2rage_statslist(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
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
    return statslist

def freesurfer_subjectlist_mp2rage(wildcards):
    # csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    # bidspath = Path(csa_complete).parents[2]
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
    #     meta_complete = check_csa_added_to_meta
    # params:
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    params:
        echo_spacing = mp2rage_echo_spacing,
        uncorr_qT1 = True
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1.json"
    threads:
        8
    resources: 
        mem_mb=200
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py -b1map_nifti {input.b1map_nifti} -inv1_nifti {input.inv1_nifti} -inv2_nifti {input.inv2_nifti} -unit1_nifti {input.unit1_nifti} -output_json {output} -echo_spacing {params.echo_spacing} -threads {threads} -uncorr_qT1 {params.uncorr_qT1}
        """


rule create_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1.nii.gz"
    threads:
        8
    container:
        "docker://hugodary/b1corr_t1map_cpp:latest"
    resources: 
        mem_mb=3000
    shell:
        """
        /opt/vol_proc/main {input}
        cp "data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/qT1_msUnit.nii.gz" {output}
        """


rule json_for_mp2proc:
    input:
        # meta_complete = check_csa_added_to_meta,
        b1map_nifti = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-famp_registeredtoMP2RAGE_ants.json",
    # params:
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    params:
        echo_spacing = mp2rage_echo_spacing
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/mp2proc.json"
    threads:
        8
    resources: 
        mem_mb=200
    shell:
        """
        python3 workflow/scripts/create_json_for_mp2proc.py -b1map_nifti {input.b1map_nifti} -inv1_nifti {input.inv1_nifti} -inv2_nifti {input.inv2_nifti} -unit1_nifti {input.unit1_nifti} -output_json {output} -echo_spacing {params.echo_spacing} -threads {threads}
        """


rule run_mp2proc:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/mp2proc.json"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qR1_pksUnit.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz",
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz"
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
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz"
    output:
         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/MP2RAGE_synthseg.nii.gz"
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


rule register_mp2rage_acqs:
    input:
        img=get_uniden,
        mask=get_mp2rage_brain_masks
    params:
        get_mp2rage_acqs
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        img_array=( {input.img} )
        acq_array=( {params} )
        mask_array=( {input.mask} )

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
                
                antsRegistration -d 3 -v 1 --transform Rigid[0.1] --metric MI[ ${{first_img}}, ${{img}}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --collapse-output-transforms 1 --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-$acq/registeredto${{first_acq}}_ -x [ ${{first_mask}}, ${{mask}} ] --random-seed 1
            done
        fi
        touch {output}
        """


rule apply_reg_first_mp2rage_acq:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done",
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{mp2rage_map}.nii.gz"
    params:
        get_mp2rage_acqs
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{mp2rage_map}_coreg.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        acq_array=( {params} )
        first_acq="${{acq_array[0]}}"
        if [ -f data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registeredto${{first_acq}}_0GenericAffine.mat ]; then    
            antsApplyTransforms -d 3 -v 1 -n Linear -i {input[1]} -r data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-$first_acq/{wildcards.mp2rage_map}.nii.gz -t data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registeredto${{first_acq}}_0GenericAffine.mat -o {output}
        else
            cp {input[1]} {output}
        fi
        """


rule crop_mp2rage_256:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{mp2rage_map}_coreg.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{mp2rage_map}_cropped.nii.gz"
    resources:
        mem_mb=1000
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        size_2="$(mrinfo -size {input} | awk '{{print $3}}')"
        start_2="$((${{size_2}}-256))"
        mrgrid {input} crop -axis 2 ${{start_2}}:end {output} -force
        mrgrid {output} crop -axis 1 0:255 {output} -force
        size_0="$(mrinfo -size {input} | awk '{{print $1}}')"
        pad_size_0="$(((256-${{size_0}})/2))"
        mrgrid {output} pad -axis 0 ${{pad_size_0}},${{pad_size_0}} {output} -force
        """


rule recon_all:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit_cropped.nii.gz"
    output:
        aparc_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
        aparc_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        orig_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.nii.gz"
    threads: 4
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
        # mri_convert --conform_min -oni 256 -onj 256 -onk 256 {input} {input}
        rm -rf $SUBJECTS_DIR/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}
        recon-all -hires -parallel -3T -i {input} -all -s sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}
        mri_convert {output.aparc_mgz} {output.aparc_nii}
        mri_convert {output.orig_mgz} {output.orig_nii}
        """


rule reslice_segmentation:
    input:
        seg=seg_first_acq_mp2rage,
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit_coreg.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz"
    resources:
        mem_mb=1000
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrgrid {input.seg} regrid -template {input.ref} -strides {input.ref} -interp nearest {output} -force
        """
    

rule mp2rage_stats:
    input:
        seg="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz",
        mp2rage_map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{mp2rage_map}_coreg.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/stats/MP2RAGE_{mp2rage_map}.stats"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license
        
        # mri_convert -oni 257 -onj 257 -onk 257 {input.mp2rage_map} {input.mp2rage_map}

        mri_segstats --seg {input.seg} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i {input.mp2rage_map} --sum {output} --excludeid 0
        """  


rule mp2rage_tsv:
    input:
        mp2rage_statslist
    params:
        freesurfer_subjectlist_mp2rage
    output:
        "data/derivatives/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats.tsv"  
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        export SUBJECTS_DIR=$HOME/data/derivatives/{wildcards.field_strength}/freesurfer/
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license

        asegstats2table --subjects {params} --statsfile MP2RAGE_{wildcards.mp2rage_map}.stats -t {output} --meas mean --common-segs --no-segno 0
        """


#rules for registering with ANTs

rule synthstrip_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain_mask.nii.gz"
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
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain.nii.gz")
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
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain_denoised.nii.gz")
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
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/{qT1}_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

