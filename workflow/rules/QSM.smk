import glob
import shutil
from pathlib import Path

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]


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
            i="$((${{vols}}-1))"
            mrconvert {input.phase} -coord 3 $i -axes 0,1,2 data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_phase.nii.gz
            mv data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_phase.nii.gz data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_echo-${{vol}}_part-phase_MEGRE.nii.gz
            mrconvert {input.mag} -coord 3 $i -axes 0,1,2 data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_mag.nii.gz
            mv data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/tmp_mag.nii.gz data/derivatives/{wildcards.field_strength}/QSM/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_echo-${{vol}}_part-mag_MEGRE.nii.gz
        done
        """


rule copy_mask_qsm:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_spine_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/{subject}/{session}/anat/{subject}_{session}_mask.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        maskfilter {input} erode {output}
        """


rule qsmxt:
    input:
        # "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/"
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.json",
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/{subject}_{session}_echo-1_part-phase_MEGRE.nii.gz"
    output:
        directory("data/derivatives/{field_strength}/QSM/derivatives/workflow/qsmxt-workflow/{subject}/{session}/")    
    threads: 4
    resources:
        mem_mb=11000
    container:
        "docker://vnmd/qsmxt_8.2.2:20260105"
    shell:
        """
        qsmxt data/derivatives/{wildcards.field_strength}/QSM --use_existing_masks --auto_yes
        mkdir data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt
        mv data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt-*/* data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt/
        rm -rf data/derivatives/{wildcards.field_strength}/QSM/derivatives/qsmxt-*/*
        """