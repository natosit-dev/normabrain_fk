import glob
import shutil
from pathlib import Path
from bids import BIDSLayout

# layout=BIDSLayout("data/rawdata/bids/3T")
# qsm_subjects=layout.get_subjects(acquisition="(?i)vibeMTmt0", regex_search=True)
# qsm_subjects = ["sub-" + x for x in qsm_subjects]
# qsm_sessions=layout.get_sessions(acquisition="(?i)vibeMTmt0", regex_search=True)
# qsm_sessions = ["ses-" + x for x in qsm_sessions]

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def qsm_nii_list(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    qsm_subjects=layout.get_subjects(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_subjects = ["sub-" + x for x in qsm_subjects]
    qsm_sessions=layout.get_sessions(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_sessions = ["ses-" + x for x in qsm_sessions]
    return expand("data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.nii.gz", subject=qsm_subjects, session=qsm_sessions, allow_missing=True)

def qsm_json_list(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    qsm_subjects=layout.get_subjects(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_subjects = ["sub-" + x for x in qsm_subjects]
    qsm_sessions=layout.get_sessions(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_sessions = ["ses-" + x for x in qsm_sessions]
    return expand("data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.json", subject=qsm_subjects, session=qsm_sessions, allow_missing=True)

def qsm_mask_list(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    bidspath = Path(csa_complete).parents[2]
    layout=BIDSLayout(bidspath)
    qsm_subjects=layout.get_subjects(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_subjects = ["sub-" + x for x in qsm_subjects]
    qsm_sessions=layout.get_sessions(acquisition="(?i)vibeMTmt0", regex_search=True)
    qsm_sessions = ["ses-" + x for x in qsm_sessions]
    return expand("data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/{subject}/{session}/anat/{subject}_{session}_mask.nii.gz", subject=qsm_subjects, session=qsm_sessions, allow_missing=True)

def get_inv1(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-*_inv-1_MP2RAGE.nii.gz'))[0]

rule copy_raw_qsm:
    input:
        check_csa_added_to_meta  
    output:
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.json"
    run: #python code, not shell
        qsm_folder = Path(str(output)).parent
        qsm_folder.mkdir(exist_ok=True, parents=True)

        phase_list = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-vibeMTmt0*_mt-off_part-phase_MPM.nii.gz'))
        num_phase = len(phase_list)
        mag_list_clipped = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-vibeMTmt0*_mt-off_part-mag_MPM.nii.gz'))[:num_phase]
        raw_list = phase_list + mag_list_clipped
        i=0
        for img in phase_list:
            i += 1
            raw = Path(img)
            qsm_name = wildcards.subject + "_" + wildcards.session + "_echo-" + str(i) + "_part-phase_MEGRE.nii.gz"
            qsm = qsm_folder / qsm_name
            # shutil.copy(raw, qsm)
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)
        i=0
        for img in mag_list_clipped:
            i += 1
            raw = Path(img)
            qsm_name = wildcards.subject + "_" + wildcards.session + "_echo-" + str(i) + "_part-mag_MEGRE.nii.gz"
            qsm = qsm_folder / qsm_name
            # shutil.copy(raw, qsm)
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)


rule copy_denoised_qsm:
    input:
        phase = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-phase_echos4d_riciancorr.nii",
        mag = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-mag_echos4d_denoise.nii"
    output:
        # "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/"
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        vols="$(mrinfo -size {input.phase} | awk '{{print $4}}')"
        for vol in $(seq 1 $vols); do
            i="$((${{vol}}-1))"
            mrconvert {input.phase} -coord 3 $i -axes 0,1,2 data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_phase.nii.gz
            mv data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_phase.nii.gz data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_echo-${{vol}}_part-phase_MEGRE.nii.gz
            mrconvert {input.mag} -coord 3 $i -axes 0,1,2 data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_mag.nii.gz
            mv data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_mag.nii.gz data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_echo-${{vol}}_part-mag_MEGRE.nii.gz
        done
        """


rule copy_raw_t1w_qsm:
    input:
        check_csa_added_to_meta
    params:
        inv1 = get_inv1
    output:
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_T1w.json"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    run:
        inv1_json = Path(params.inv1).with_suffix("").with_suffix(".json")
        shutil.copy(inv1_json, str(output))

        
rule copy_uniden_qsm:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_T1w.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    shell:
        """
        cp {input} {output}
        """


rule copy_mask_qsm:
    input:
        mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTt1w_mt-off_part-mag_sos_brain_spine_mask.nii.gz",
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-mag_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-mag_registeredtovibeMTt1w_Composite.h5"
    output:
        "data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/{subject}/{session}/anat/{subject}_{session}_mask.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        maskfilter {input.mask} erode {output} -force
        antsApplyTransforms -d 3 -v 1 -n NearestNeighbor -i {output} -r {input.ref} -t [ {input.reg}, 1 ] -o {output}
        """

# rule copy_seg_qsm:
#     input:
#         seg = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/MP2RAGE_synthseg.nii.gz",
#         ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-mag_sos.nii.gz",
#         T1toMP2RAGE =  "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-vibeMT_registeredtoMP2RAGE_Composite.h5",
#         MT0toT1 = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-vibeMTmt0_mt-off_part-mag_registeredtovibeMTt1w_Composite.h5"
#     output:
#         "data/derivatives/{field_strength}/QSM/derivatives/synthseg/{subject}/{session}/anat/{subject}_{session}_dseg.nii.gz"
#     resources: #limit memory by input size
#         mem_mb=lambda wc, input: 2.5 * input.size_mb
#     conda:
#         "../envs/qMT.yaml"
#     shell:
#         """
#         antsApplyTransforms -d 3 -v 1 -n NearestNeighbor -i {input.seg} -r {input.ref} -t [ {input.T1toMP2RAGE}, 1 ] -t [ {input.MT0toT1}, 1 ] -o {output}
#         """

rule qsmxt:
    input:
        qsm_nii_list,
        qsm_json_list,
        qsm_mask_list
        # expand("data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_T1w.json", subject=qsm_subjects, session=qsm_sessions, allow_missing=True),
        # expand("data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_T1w.nii.gz", subject=qsm_subjects, session=qsm_sessions, allow_missing=True),
        # expand("data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/{subject}/{session}/anat/{subject}_{session}_mask.nii.gz", subject=qsm_subjects, session=qsm_sessions, allow_missing=True),
        # expand("data/derivatives/{field_strength}/QSM/derivatives/synthseg/{subject}/{session}/anat/{subject}_{session}_dseg.nii.gz", subject=qsm_subjects, session=qsm_sessions, allow_missing=True)
    output:
        directory("data/derivatives/{field_strength}/QSM/derivatives/qsmxt/")    
    threads: 8
    resources:
        mem_mb=11000
    container:
        "docker://vnmd/qsmxt_8.2.2:20260105"
    shell:
        """
        qsmxt data/derivatives/{wildcards.field_strength}/QSM --premade 'body' --auto_yes
        mkdir -p data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt
        mv data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt-*/* data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt/
        rm -rf data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt-*
        """