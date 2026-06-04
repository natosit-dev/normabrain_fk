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
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
                apply_reg_list.append("data/derivatives/{field_strength}/MPM/sub-" + subject + "/ses-" + session + "/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_apply_reg_MPM_to_" + mp2rage_first_acq + "_ants.done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count == 4]
    return apply_reg_list

def ihmt_to_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
                apply_reg_list.append("data/derivatives/{field_strength}/ihmt/sub-" + subject + "/ses-" + session + "/acq-" + ihmt + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-" + ihmt + "_applyreg2" + mp2rage_first_acq + "_ants.done")
    return apply_reg_list

def dwi_to_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath, validate=False)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_dwi))
        for session in sessionlist:
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for dwi in dwi_acqlist:
                dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "")
                apply_reg_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/sub-" + subject + "_ses-" + session + "_acq-" + dwi + "_reg2" + mp2rage_first_acq + "/sub-" + subject + "_ses-" + session + "_acq-" + dwi + "_apply_reg_DWIto" + mp2rage_first_acq + ".done" )
    return apply_reg_list

def ihmt_reg2first_acq_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat", mp2rage_params=first_acq, allow_missing=True)

def mpm_reg2first_acq_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}_0GenericAffine.mat", mp2rage_params=first_acq, allow_missing=True)

def dwi_reg2first_acq_mp2rage(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}.lta", mp2rage_params=first_acq, allow_missing=True)

def ihmt_statslist(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
    return sorted(statslist)

def mpm_statslist(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
    return sorted(statslist)

def dwi_statslist(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_mpm))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "")
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/dwi_stats.done")
    return sorted(statslist)

def freesurfer_subjectlist_ihmt(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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

def freesurfer_subjectlist_dwi(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_dwi))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "")
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    fs_subjectlist = list(set(fs_subjectlist))
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def mp2rage_to_ihmt(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2ihmt_ants/apply_reg_MP2RAGE_to_" + ihmt + "_ants.done")
    return apply_reg_list

def mp2rage_to_mpm(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
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
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2" + mpm + "_ants/apply_reg_MP2RAGE_to_" + mpm + "_ants.done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count == 4]
    return apply_reg_list

def mp2rage_to_dwi(wildcards):
    bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=BIDSLayout(bidspath)
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & set(subjectlist_tb1tfl) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & set(sessionlist_tb1tfl) & set(sessionlist_dwi))
        for session in sessionlist:
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for dwi in dwi_acqlist:
                dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "")
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2DWI" + dwi + "/apply_reg_MP2RAGE_to_DWI" + dwi + ".done")
    return apply_reg_list

rule register_ihmt_to_MP2RAGE_ants:
    input:
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
        moving="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
        ref_mask="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz",
        moving_mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    params:
        outprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    threads: 4
    log:
       "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        antsRegistration \
        --random-seed 1 \
        --dimensionality 3 \
        --verbose 1 \
        --convergence [ 1000x500x250x100, 1e-7, 100 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 4x2x1x0vox \
        --transform Rigid[0.1] \
        --metric MI[ {input.ref}, {input.moving}, 1, 32 ] \
        -o {params.outprefix} \
        -x [ {input.ref_mask}, {input.moving_mask} ]
        """


rule apply_reg_ihmt_to_MP2RAGE_ants:
    input:
        ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        acqdir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/",
        subject="sub-{subject}_ses-{session}_acq-{ihmt_params}"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2{mp2rage_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2{mp2rage_params}_ants.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        mkdir -p "{params.acqdir}/reg2MP2RAGE"
        for map in "${{MTmaps[@]}}"; do
            moving="{params.acqdir}/{params.subject}_"$map".nii.gz"
            out="{params.acqdir}/reg2MP2RAGE/{params.subject}_"$map"_reg2{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms \
                --dimensionality 3 \
                --interpolation Linear \
                --verbose 1 \
                -i $moving \
                -r {input.ref} \
                -t {input.reg} \
                -o $out
            fi
        done
        touch {output}
        """


rule gather_ihmt_to_MP2RAGE_ants:
    input:
        ihmt_to_mp2rage
    output:
        "data/derivatives/{field_strength}/ihmt/ihmt_to_MP2RAGE.done"
    log:
        "logs/{field_strength}/ihmt/ihmt_to_MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_reg_seg_to_ihmt_ants:
    input:
        seg = resliced_seg_first_acq_mp2rage,
        reg = ihmt_reg2first_acq_mp2rage
    params:
        refprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/aparc+aseg_reg2IHMT.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    threads: 1
    log:
       "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/aparc+aseg_reg2IHMT.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        #choose ref based on what maps are available
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd")
        for map in "${{MTmaps[@]}}"; do
            ref_init="{params.refprefix}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done
        
        #apply inverse reg so that seg is in ihmt space, to avoid interpolation of ihmt
        antsApplyTransforms \
        --dimensionality 3 \
        --interpolation NearestNeighbor \
        --verbose 1 \
        -i {input.seg} \
        -r $ref \
        -t [ {input.reg}, 1 ] \
        -o {output}
        """


rule ihmt_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/aparc+aseg_reg2IHMT.nii.gz"
    params:
        ihmtprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
        statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/stats/ihmt"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/stats/ihmt_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/ihmt_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        
        for map in "${{MTmaps[@]}}"; do
            ihmt="{params.ihmtprefix}_${{map}}.nii.gz"
            stats="{params.statsprefix}_${{map}}.stats"
            if [ -f $ihmt ]; then
                mri_segstats --seg {input} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $ihmt --sum $stats --excludeid 0
            fi
        done

        touch {output}
        """


rule ihmt_tsv:
    input:
        ihmt_statslist
    params:
        subjectlist=freesurfer_subjectlist_ihmt,
        subjects_dir="data/derivatives/{field_strength}/freesurfer/"
    output:
        "data/derivatives/{field_strength}/freesurfer/ihmt_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/ihmt_stats_tsv.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
        
        for map in "${{MTmaps[@]}}"; do
            asegstats2table --subjects {params.subjectlist} --statsfile ihmt_${{map}}.stats -t $SUBJECTS_DIR/ihmt_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_ihmt_ants:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        ihmt_prefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        mp2rage_subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2ihmt_ants/apply_reg_MP2RAGE_to_{ihmt_params}_ants.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_ants.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        #set reference based on what maps are availble
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd")
        for map in "${{MTmaps[@]}}"; do
            ref_init="{params.ihmt_prefix}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done

        MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/reg2{wildcards.ihmt_params}_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="{params.mp2rage_acqdir}/{params.mp2rage_subject}_"$map".nii.gz"
            out="{params.mp2rage_acqdir}/reg2{wildcards.ihmt_params}_ants/{params.mp2rage_subject}_"$map"_reg2{wildcards.ihmt_params}.nii.gz"

            #apply inverse of ihmt to MP2RAGE transform to each MP2RAGE map
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i $moving \
            -r $ref \
            -t [ {input.reg}, 1 ] \
            -o $out
        done
        touch {output}
        """


rule gather_MP2RAGE_to_ihmt_ants:
    input:
        mp2rage_to_ihmt
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule register_MPM_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{mpm_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    params:
        outprefix="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}_"
    output:
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    threads: 4
    log:
       "logs/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        antsRegistration \
        --random-seed 1 \
        --dimensionality 3 \
        --verbose 1 \
        --convergence [ 1000x500x250x100, 1e-7, 100 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 4x2x1x0vox \
        --transform Rigid[0.1] \
        --metric MI[ {input.ref}, {input.moving}, 1, 32 ] \
        -o {params.outprefix} \
        -x [ {input.ref_mask}, {input.moving_mask} ]
        """


rule apply_reg_MPM_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        sessiondir="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/",
        regto="reg2{mp2rage_params}",
        mpmprefix="sub-{subject}_ses-{session}_acq-{seq}{mpm_params}"
    output:
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_apply_reg_MPM_to_{mp2rage_params}_ants.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_apply_reg_MPM_to_{mp2rage_params}_ants.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        mkdir -p {params.sessiondir}/{params.regto}_ants
        for map in "${{MPMmaps[@]}}"; do
            moving="{params.sessiondir}/{params.mpmprefix}_"$map".nii.gz"
            out="{params.sessiondir}/{params.regto}_ants/{params.mpmprefix}_"$map"_{params.regto}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms \
                --dimensionality 3 \
                --interpolation Linear \
                --verbose 1 \
                -i $moving \
                -r {input.ref} \
                -t {input.reg} \
                -o $out
            fi
        done
        touch {output}
        """


rule gather_MPM_to_MP2RAGE_ants:
    input:
        mpm_to_mp2rage
    output:
        "data/derivatives/{field_strength}/MPM/MPM_to_MP2RAGE.done"
    log:
        "logs/{field_strength}/MPM/MPM_to_MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        touch {output}
        """


rule apply_reg_seg_to_mpm_ants:
    input:
        seg = resliced_seg_first_acq_mp2rage,
        reg = mpm_reg2first_acq_mp2rage,
        ref = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/mri/aparc+aseg_reg2MPM.nii.gz"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/aparc+aseg_reg2MPM.log"
    shell:
        """ 
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        #apply inverse reg so that seg is in mpm space, to avoid interpolation of mpm
        antsApplyTransforms \
        --dimensionality 3 \
        --interpolation NearestNeighbor \
        --verbose 1 \
        -i {input.seg} \
        -r {input.ref} \
        -t [ {input.reg}, 1 ] \
        -o {output}
        """
  

rule mpm_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/mri/aparc+aseg_reg2MPM.nii.gz",
        "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_MTRmap.nii.gz"
    params:
        mpmprefix="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}",
        statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/stats/MPM"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/stats/MPM_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
       "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}/MPM_stats.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        for map in "${{MPMmaps[@]}}"; do
            mpm="{params.mpmprefix}_"$map".nii.gz"
            stats="{params.statsprefix}_${{map}}.stats"
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
        subjectlist=freesurfer_subjectlist_mpm,
        subjects_dir="data/derivatives/{field_strength}/freesurfer/"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
      "logs/{field_strength}/freesurfer/MPM_stats_tsv.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        for map in "${{MPMmaps[@]}}"; do
            asegstats2table --subjects {params.subjectlist} --statsfile MPM_${{map}}.stats -t $SUBJECTS_DIR/MPM_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_MPM_ants:
    input:
        ref="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_T1map.nii.gz",
        reg="data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{mpm_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        regto="reg2{seq}{mpm_params}",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2{seq}{mpm_params}_ants/apply_reg_MP2RAGE_to_{seq}{mpm_params}_ants.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2{seq}{mpm_params}_ants/apply_reg_MP2RAGE_to_{seq}{mpm_params}_ants.done"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/{params.regto}_ants
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="{params.mp2rage_acqdir}/{params.subject}_"$map".nii.gz"
            out="{params.mp2rage_acqdir}/{params.regto}_ants/{params.subject}_"$map"_{params.regto}.nii.gz"

            #apply inverse of MPM to MP2RAGE registration
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i $moving \
            -r {input.ref} \
            -t [ {input.reg}, 1 ] \
            -o $out
        done
        touch {output}
        """


rule gather_MP2RAGE_to_MPM_ants:
    input:
        mp2rage_to_mpm
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_MPM.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_to_MPM.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule register_DWI_to_MP2RAGE_bbregister:
    input:
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dwi_designer_meanb0_brain.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}.lta"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}",
        outbase="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}"
    resources:
        mem_mb=1500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}.log"
    shell:
        """
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license
        
        bbregister --s {params.subject} --mov {input.meanb0} --reg {output} --dti --init-fsl --9
        mv {params.outbase}.log {log}
        """


rule apply_reg_DWI_to_MP2RAGE_bbregister:
    input:
        reg="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}.lta",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        moving="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dki/"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_apply_reg_DWIto{mp2rage_params}.done"
    params:
        sessiondir="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/",
        regto="reg2{mp2rage_params}",
        dwiprefix="sub-{subject}_ses-{session}_acq-{dwi_params}"
    resources:
        mem_mb=1500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_apply_reg_DWIto{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")

        for map in "${{dkimaps[@]}}"; do
            moving="{params.sessiondir}/{params.dwiprefix}_dki/{params.dwiprefix}_"$map".nii.gz"
            out="{params.sessiondir}/{params.dwiprefix}_{params.regto}/dki/{params.dwiprefix}_{params.regto}_"$map".nii.gz"
            if [ -f $moving ]; then
                mri_vol2vol --mov $moving --targ {input.target} --o $out --reg {input.reg} --no-save-reg
            fi
        done
        touch {output}
        """


rule gather_DWI_to_MP2RAGE_bbregister:
    input:
        dwi_to_mp2rage
    output:
        "data/derivatives/{field_strength}/dwi/DWI_to_MP2RAGE.done"
    log:
        "logs/{field_strength}/dwi/DWI_to_MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_reg_seg_to_dwi_bbregister:
    input:
        seg = resliced_seg_first_acq_mp2rage,
        reg = dwi_reg2first_acq_mp2rage,
        b0 = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dwi_designer_meanb0_brain.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/mri/aparc+aseg_reg2DWI.nii.gz"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/aparc+aseg_reg2DWI.log"
    shell:
        """ 
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #apply inverse reg so that seg is in dwi space, to avoid interpolation of dwi
        mri_vol2vol --mov {input.b0} --targ {input.seg} --inv --interp nearest --o {output} --reg {input.reg} --no-save-reg
        """


rule dwi_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/mri/aparc+aseg_reg2DWI.nii.gz",
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dki/"
    params:
        dkiprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dki/sub-{subject}_ses-{session}_acq-{dwi_params}",
        statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/stats/dki"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/stats/dwi_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
       "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{dwi_params}/dwi_stats.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        
        for map in "${{dkimaps[@]}}"; do
            mpm="{params.dkiprefix}_"$map".nii.gz"
            stats="{params.statsprefix}_${{map}}.stats"
            if [ -f $mpm ]; then
                mri_segstats --seg {input[0]} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $mpm --sum $stats --excludeid 0
            fi
        done

        touch {output}
        """


rule dwi_tsv:
    input:
        dwi_statslist
    output:
        "data/derivatives/{field_strength}/freesurfer/dwi_stats.done"
    params:
        subjectlist=freesurfer_subjectlist_dwi,
        subjects_dir="data/derivatives/{field_strength}/freesurfer/"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
      "logs/{field_strength}/freesurfer/dwi_stats_tsv.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        
        for map in "${{dkimaps[@]}}"; do
            asegstats2table --subjects {params.subjectlist} --statsfile dki_${{map}}.stats -t $SUBJECTS_DIR/dki_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip
        done
        touch {output}
        """


rule apply_reg_MP2RAGE_to_dwi_bbregister:
    input:
        b0 = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dwi_designer_meanb0_brain.nii.gz",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        reg = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}/sub-{subject}_ses-{session}_acq-{dwi_params}_reg2{mp2rage_params}.lta"
    params:
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        regto="reg2DWI{dwi_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2DWI{dwi_params}/apply_reg_MP2RAGE_to_DWI{dwi_params}.done"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2DWI{dwi_params}/apply_reg_MP2RAGE_to_DWI{dwi_params}.done"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MP2RAGEmaps=("R1map_b1corr" "qT1_msUnit" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/{params.regto}
        for map in "${{MP2RAGEmaps[@]}}"; do
            target="{params.mp2rage_acqdir}/"$map".nii.gz"
            out="{params.mp2rage_acqdir}/{params.regto}/"$map"_{params.regto}.nii.gz"

            #apply inverse of MPM to MP2RAGE registration
            mri_vol2vol --mov {input.b0} --targ $target --inv --o $out --reg {input.reg} --no-save-reg
        done
        touch {output}
        """


rule gather_MP2RAGE_to_dwi_bbregister:
    input:
        mp2rage_to_dwi
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_DWI.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_to_DWI.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

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
#         # moving_reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_T1map_reg2MP2RAGE_easyreg.nii.gz",
#         fwd_field = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGEmatrix.nii.gz",
#         bak_field = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGEmatrix_inverse.nii.gz"
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
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGEmatrix.nii.gz"
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
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_easyreg
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_easyreg/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map"_reg2MP2RAGE.nii.gz"
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
#         reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGE.lta",
#         reg_inv = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGE_inverse.lta"
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
#         reg = "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGE.lta"
#     output:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell: #register and reslice to MP2RAGE
#         """
#         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_synthmorph
#         for map in "${{MPMmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_synthmorph/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}_"$map"_reg2MP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_synthmorph apply {input.reg} $moving $out
#             fi
#         done
#         touch {output}
        
#         """  


# rule apply_reg_MP2RAGE_to_ihmt_easyreg:
#     input:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGEmatrix_inverse.nii.gz",
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
#         MP2RAGEmaps=("R1map_b1corr" "qT1_msUnit" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2ihmt_easyreg
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2ihmt_easyreg/"$map"_reg2{wildcards.ihmt_params}.nii.gz"
#             mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_MPM_easyreg:
#     input:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGEmatrix_inverse.nii.gz",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_easyreg.done"
#     threads: 8
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("R1map_b1corr" "qT1_msUnit" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2{wildcards.seq}_easyreg
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/reg2{wildcards.seq}_easyreg/acq-{wildcards.mp2rage_params}/"$map"_reg2{wildcards.seq}.nii.gz"
#             mri_easywarp --i $moving --o $out --field {input[0]} --threads {threads}
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_ihmt_synthmorph:
#     input:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGE_inverse.lta",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{ihmt_params}_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("R1map_b1corr" "qT1_msUnit" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2ihmt_synthmorph
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2ihmt_synthmorph/"$map"_reg2{wildcards.ihmt_params}.nii.gz"
#             mri_synthmorph apply {input[0]} $moving $out
#         done
#         touch {output}
#         """


# rule apply_reg_MP2RAGE_to_MPM_synthmorph:
#     input:
#         "data/derivatives/{field_strength}/MPM/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}_reg2MP2RAGE_inverse.lta",
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/apply_reg_MP2RAGE_to_{seq}_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MP2RAGEmaps=("R1map_b1corr" "qT1_msUnit" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2{wildcards.seq}_synthmorph
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MP2RAGE/sub-{wildcards.subject}/ses-{wildcards.session}/acq-{wildcards.mp2rage_params}/reg2{wildcards.seq}_synthmorph/"$map"_reg2{wildcards.seq}.nii.gz"
#             mri_synthmorph apply {input[0]} $moving $out
#         done
#         touch {output}
#         """

# #rules for registering to MP2RAGE with easyreg

# rule register_ihmt_to_MP2RAGE_easyreg:
#     input:
#         moving = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/T1w_UNIDEN.nii.gz",
#         ref_seg = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/MP2RAGE_synthseg.nii.gz"
#     params:
#         moving_seg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_seg.nii.gz"
#     output:
#         # moving_reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_MTmap_reg2MP2RAGE_easyreg.nii.gz",
#         fwd_field = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGEmatrix.nii.gz",
#         bak_field = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGEmatrix_inverse.nii.gz"
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
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGEmatrix.nii.gz"
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
#         mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_easyreg
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_easyreg/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_reg2MP2RAGE.nii.gz"
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
#         ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/T1w_UNIDEN.nii.gz"
#     output:
#         reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGE.lta",
#         reg_inv = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{ihmt_params}_IHMTreg2MP2RAGE_inverse.lta"
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
#         # ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/T1w_UNI_b1corr.nii.gz",
#         reg = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_IHMTreg2MP2RAGE.lta"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_apply_reg_ihmt_to_MP2RAGE_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell: #register and reslice to MP2RAGE
#         """
#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTmap" "freqalt_ihMTmap" "cosmod_ihMTR" "freqalt_ihMTR")
#         mkdir -p data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_synthmorph
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/ihmt/sub-{wildcards.subject}/ses-{wildcards.session}/reg2MP2RAGE_synthmorph/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.ihmt_params}_"$map"_reg2MP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_synthmorph apply {input.reg} $moving $out
#             fi
#         done
#         touch {output}
        
#         """  
