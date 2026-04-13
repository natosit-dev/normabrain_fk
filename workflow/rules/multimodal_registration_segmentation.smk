#rules for multimodal registration and segmentation, not including B1map which is a dependency for regular pre-processing for MP2RAGE and MPM
#dependent on all other smk files
from bids import BIDSLayout
from collections import Counter
from pathlib import Path


wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"],
    part = 'mag|phase'


def mpm_to_mp2rage(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_mpm))
        for session in sessionlist:
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "")
                for contrast in config["MPM_contrasts"]:
                    mpm = mpm.replace(contrast, "")
                apply_reg_list.append("data/derivatives/{field_strength}/MPM/sub-" + subject + "/ses-" + session + "/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_apply_reg_MPM_to_MP2RAGE" + mp2rage_first_acq + "_ants.done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count == 4]
    return apply_reg_list

def ihmt_to_mp2rage(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath, validate=False)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_ihmt))
        for session in sessionlist:
            ihmt_acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for ihmt in ihmt_acqlist:
                apply_reg_list.append("data/derivatives/{field_strength}/ihmt/sub-" + subject + "/ses-" + session + "/sub-" + subject + "_ses-" + session + "_acq-" + ihmt + "_apply_reg_ihmt_to_MP2RAGE" + mp2rage_first_acq + "_ants.done")
    return apply_reg_list

def ihmt_reg_to_first_acq_mp2rage(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE{mp2rage_params}_0GenericAffine.mat", mp2rage_params=first_acq, allow_missing=True)

def mpm_reg_to_first_acq_mp2rage(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5", mp2rage_params=first_acq, allow_missing=True)

def ihmt_statslist(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath, validate=False)
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_ihmt))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for acq in acqlist:
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/ihmt_stats.done")
    return statslist

def mpm_statslist(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_mpm))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("6eco", "").replace("3eco", "").replace("sag", "")
                for contrast in config["MPM_contrasts"]:
                    acq = acq.replace(contrast, "")
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/MPM_stats.done")
    counts = Counter(statslist)
    statslist = [stat for stat, count in counts.items() if count == 4]
    return statslist

def freesurfer_subjectlist_ihmt(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath, validate=False)
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_ihmt))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for acq in acqlist:
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def freesurfer_subjectlist_mpm(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_mpm))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("6eco", "").replace("3eco", "").replace("sag", "")
                for contrast in config["MPM_contrasts"]:
                    acq = acq.replace(contrast, "")
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    counts = Counter(fs_subjectlist)
    fs_subjectlist = [sub for sub, count in counts.items() if count == 4]
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def mp2rage_to_ihmt(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath, validate=False)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_ihmt))
        for session in sessionlist:
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            ihmt_acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for ihmt in ihmt_acqlist:
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/registered_to_ihmt_ants/apply_reg_MP2RAGE_to_" + ihmt + "_ants.done")
    return apply_reg_list

def mp2rage_to_mpm(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_mpm))
        for session in sessionlist:
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "")
                for contrast in config["MPM_contrasts"]:
                    mpm = mpm.replace(contrast, "")
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/registered_to_" + mpm + "_ants/apply_reg_MP2RAGE_to_" + mpm + "_ants.done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count == 4]
    return apply_reg_list


rule register_ihmt_to_MP2RAGE_ants:
    input:
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz",
        moving="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
        ref_mask="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4_registeredtoMP2RAGE{mp2rage_params}.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_dicomUnit_registeredtoIHMT{ihmt_params}.nii.gz"),
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE{mp2rage_params}_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    shell:
        """
        antsRegistration -d 3 -v 1 --transform Affine[0.1] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-7, 100 ] --shrink-factors 8x4x2x1 -s 4x2x1x0vox -o [ data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_IHMTregisteredtoMP2RAGE{wildcards.mp2rage_params}_, {output[0]}, {output[1]} ] -x [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """


rule apply_reg_ihmt_to_MP2RAGE_ants:
    input:
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE{mp2rage_params}_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_apply_reg_ihmt_to_MP2RAGE{mp2rage_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_ants
        for map in "${{MTmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_ants/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t {input.reg} -o $out
            fi
        done
        touch {output}
        """


rule gather_ihmt_to_MP2RAGE_ants:
    input:
        ihmt_to_mp2rage
    output:
        "data/derivatives/{field_strength}/ihmt/ihmt_to_MP2RAGE.done"
    shell:
        """
        touch {output}
        """


rule apply_reg_seg_to_ihmt_ants:
    input:
        seg = resliced_seg_first_acq_mp2rage,
        reg = ihmt_reg_to_first_acq_mp2rage
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/aparc+aseg_registeredtoIHMT.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd")
        for map in "${{MTmaps[@]}}"; do
            ref_init="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done
        
        antsApplyTransforms -d 3 -v 1 -n NearestNeighbor -i {input.seg} -r $ref -t [ {input.reg}, 1 ] -o {output}
        """


rule ihmt_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/aparc+aseg_registeredtoIHMT.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/stats/ihmt_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license

        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        
        for map in "${{MTmaps[@]}}"; do
            ihmt="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_${{map}}.nii.gz"
            stats="data/derivatives/{wildcards.field_strength}/freesurfer/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}/stats/ihmt_${{map}}.stats"
            if [ -f $ihmt ]; then
                mri_segstats --seg {input} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $ihmt --sum $stats --excludeid 0
            fi
        done
        touch {output}
        """


rule ihmt_tsv:
    input:
        ihmt_statslist
    output:
        "data/derivatives/{field_strength}/freesurfer/ihmt_stats.done"
    params:
        freesurfer_subjectlist_ihmt
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        export SUBJECTS_DIR=$HOME/data/derivatives/{wildcards.field_strength}/freesurfer/
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license

        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        
        for map in "${{MTmaps[@]}}"; do
            asegstats2table --subjects {params} --statsfile ihmt_${{map}}.stats -t data/derivatives/{wildcards.field_strength}/freesurfer/ihmt_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip
        done
        touch {output}
        """


rule apply_reg_seg_to_mpm_ants:
    input:
        seg = resliced_seg_first_acq_mp2rage,
        reg = mpm_reg_to_first_acq_mp2rage,
        ref = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/mri/aparc+aseg_registeredtoMPM.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """      
        antsApplyTransforms -d 3 -v 1 -n NearestNeighbor -i {input.seg} -r {input.ref} -t [ {input.reg}, 1 ] -o {output}
        """
  

rule mpm_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/mri/aparc+aseg_registeredtoMPM.nii.gz",
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_MTRmap.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/stats/MPM_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license

        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        for map in "${{MPMmaps[@]}}"; do
            mpm="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.mpm_params}_"$map".nii.gz"
            stats="data/derivatives/{wildcards.field_strength}/freesurfer/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.mpm_params}/stats/MPM_${{map}}.stats"
            if [ -f $mpm ]; then
                mri_segstats --seg {input[0]} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $mpm --sum $stats --excludeid 0
            fi
        done
        touch {output}
        """


rule mpm_tsv:
    input:
        mpm_statslist
    output:
        "data/derivatives/{field_strength}/freesurfer/MPM_stats.done"
    params:
        freesurfer_subjectlist_mpm
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        export SUBJECTS_DIR=$HOME/data/derivatives/{wildcards.field_strength}/freesurfer/
        cp $HOME/.snakemake/scripts/.license $HOME
        export FS_LICENSE=$HOME/.license

         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        for map in "${{MPMmaps[@]}}"; do
            asegstats2table --subjects {params} --statsfile MPM_${{map}}.stats -t data/derivatives/{wildcards.field_strength}/freesurfer/MPM_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_ihmt_ants:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE{mp2rage_params}_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/registered_to_ihmt_ants/apply_reg_MP2RAGE_to_{ihmt_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd")
        for map in "${{MTmaps[@]}}"; do
            ref_init="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done

        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_ants/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
            antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r $ref -t [ {input.reg}, 1 ] -o $out
        done
        touch {output}
        """


rule gather_MP2RAGE_to_ihmt_ants:
    input:
        mp2rage_to_ihmt
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.done"
    shell:
        """
        touch {output}
        """


rule apply_reg_MP2RAGE_to_MPM_ants:
    input:
        ref="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map.nii.gz",
        reg="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/registered_to_{seq}{mpm_params}_ants/apply_reg_MP2RAGE_to_{seq}{mpm_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
        mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}{wildcards.mpm_params}_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}{wildcards.mpm_params}_ants/"$map"_registeredto{wildcards.seq}{wildcards.mpm_params}.nii.gz"
            antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t [ {input.reg}, 1 ] -o $out
        done
        touch {output}
        """


rule gather_MP2RAGE_to_MPM_ants:
    input:
        mp2rage_to_mpm
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_MPM.done"
    shell:
        """
        touch {output}
        """


rule register_MPM_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{mpm_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map_brain_denoised_n4_registeredtoMP2RAGE{mp2rage_params}.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit_brain_denoised_n4_registeredto{seq}{mpm_params}T1map.nii.gz"),
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5",
        temp("data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_registeredtoMP2RAGE{mp2rage_params}_InverseComposite.h5")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    shell:
        """
        antsRegistration --verbose 1 --dimensionality 3 --float 0 --write-composite-transform 1 --collapse-output-transforms 1 --output [ data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.mpm_params}_registeredtoMP2RAGE{wildcards.mp2rage_params}_, {output[0]}, {output[1]} ] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] --initial-moving-transform [ {input.ref}, {input.moving}, 1 ] --transform Affine[ 0.1 ] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-6, 50 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 4x2x1x0vox --masks [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """


rule apply_reg_MPM_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5"
    output:
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_apply_reg_MPM_to_MP2RAGE{mp2rage_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        mkdir -p data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE{wildcards.mp2rage_params}_ants
        for map in "${{MPMmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.mpm_params}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE{wildcards.mp2rage_params}_ants/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.mpm_params}_"$map"_registeredtoMP2RAGE{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t {input.reg} -o $out
            fi
        done
        touch {output}
        """


rule gather_MPM_to_MP2RAGE_ants:
    input:
        mpm_to_mp2rage
    output:
        "data/derivatives/{field_strength}/MPM/MPM_to_MP2RAGE.done"
    shell:
        """
        touch {output}
        """


# #rules for registration with easyreg

# rule register_MPM_to_MP2RAGE_easyreg:
#     input:
#         moving = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map.nii.gz",
#         # moving_seg = "data/derivatives/{ield_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map_seg.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/qT1_msUnit.nii.gz",
#         ref_seg = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/MP2RAGE_synthseg.nii.gz"
#     params:
#         moving_seg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map_seg.nii.gz"
#     output:
#         # moving_reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map_registeredtoMP2RAGE_easyreg.nii.gz",
#         fwd_field = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGEmatrix.nii.gz",
#         bak_field = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGEmatrix_inverse.nii.gz"
#     resources:
#         mem_mb=15000
#     threads: 8
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_easyreg --ref {input.ref} --flo {input.moving} --ref_seg {input.ref_seg} --flo_seg {params.moving_seg} --fwd_field {output.fwd_field} --bak_field {output.bak_field} --threads {threads} --affine_only
#         """


# rule apply_reg_MPM_to_MP2RAGE_easyreg:
#     input:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGEmatrix.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE_easyreg.done"
#     threads: 8
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_easyreg
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_easyreg/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_easywarp --i $moving --o $out --field {input} --threads {threads}
#             fi
#         done
#         touch {output}
#         """


# #rules for registration with synthmorph

# rule register_MPM_to_MP2RAGE_synthmorph:
#     input:
#         moving = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map_brain.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/qT1_msUnit_brain.nii.gz"
#     output:
#         reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGE.lta",
#         reg_inv = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGE_inverse.lta"
#     resources: 
#         mem_mb=7000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref}
#         lta_convert --inlta {output.reg} --outlta {output.reg_inv} --invert
#         """


# rule apply_reg_MPM_to_MP2RAGE_synthmorph:
#     input:
#         # moving = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map.nii.gz",
#         # ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/qT1_msUnit.nii.gz",
#         reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGE.lta"
#     output:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell: #register and reslice to MP2RAGE
#         """
#         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_synthmorph
#         for map in "${{MPMmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_synthmorph/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_synthmorph apply {input.reg} $moving $out
#             fi
#         done
#         touch {output}
        
#         """  


# rule apply_reg_MP2RAGE_to_ihmt_easyreg:
#     input:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix_inverse.nii.gz",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_easyreg.done"
#     threads: 8
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_easyreg
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_easyreg/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
#             mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_MPM_easyreg:
#     input:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGEmatrix_inverse.nii.gz",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_easyreg.done"
#     threads: 8
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_easyreg
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_{wildcards.seq}_easyreg/acq-{wildcards.mp2rage_params}/"$map"_registeredto{wildcards.seq}.nii.gz"
#             mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_ihmt_synthmorph:
#     input:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_inverse.lta",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_synthmorph
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_ihmt_synthmorph/"$map"_registeredto{wildcards.ihmt_params}.nii.gz"
#             mri_synthmorph apply {input[0]} $moving $out
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_MPM_synthmorph:
#     input:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_registeredtoMP2RAGE_inverse.lta",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("qR1_pksUnit" "qT1_msUnit" "t1wUNI_B1Corrected_DEN_dicomUnit" "t1wUNI_B1Corrected_dicomUnit" "t1wUNI_DEN_dicomUnit")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_synthmorph
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/registered_to_{wildcards.seq}_synthmorph/"$map"_registeredto{wildcards.seq}.nii.gz"
#             mri_synthmorph apply {input[0]} $moving $out
#         done
#         touch {output}
#         """

# #rules for registering to MP2RAGE with easyreg

# rule register_ihmt_to_MP2RAGE_easyreg:
#     input:
#         moving = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/t1wUNI_DEN_dicomUnit.nii.gz",
#         ref_seg = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/MP2RAGE_synthseg.nii.gz"
#     params:
#         moving_seg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_seg.nii.gz"
#     output:
#         # moving_reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_MTmap_registeredtoMP2RAGE_easyreg.nii.gz",
#         fwd_field = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix.nii.gz",
#         bak_field = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix_inverse.nii.gz"
#     resources:
#         mem_mb=15000
#     threads: 8
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_easyreg --ref {input.ref} --flo {input.moving} --ref_seg {input.ref_seg} --flo_seg {params.moving_seg} --fwd_field {output.fwd_field} --bak_field {output.bak_field} --threads {threads} --affine_only
#         """


# rule apply_reg_ihmt_to_MP2RAGE_easyreg:
#     input:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGEmatrix.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_apply_reg_ihmt_to_MP2RAGE_easyreg.done"
#     threads: 8
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
#         mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_easyreg
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_easyreg/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_easywarp --i $moving --o $out --field {input} --threads {threads}
#             fi
#         done
#         touch {output}
#         """

# #rules for registering to MP2RAGE with synthmorph

# rule register_ihmt_to_MP2RAGE_synthmorph:
#     input:
#         moving = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/t1wUNI_DEN_dicomUnit.nii.gz"
#     output:
#         reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE.lta",
#         reg_inv = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTregisteredtoMP2RAGE_inverse.lta"
#     resources: 
#         mem_mb=7000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref}
#         lta_convert --inlta {output.reg} --outlta {output.reg_inv} --invert
#         """

# rule apply_reg_ihmt_to_MP2RAGE_synthmorph:
#     input:
#         # moving = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_MTmap.nii.gz",
#         # ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/t1wUNI_B1Corrected_dicomUnit.nii.gz",
#         reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_IHMTregisteredtoMP2RAGE.lta"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_apply_reg_ihmt_to_MP2RAGE_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell: #register and reslice to MP2RAGE
#         """
#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
#         mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_synthmorph
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/registered_to_MP2RAGE_synthmorph/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_synthmorph apply {input.reg} $moving $out
#             fi
#         done
#         touch {output}
        
#         """  
