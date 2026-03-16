import glob
import shutil
from pathlib import Path

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_raw_qsm_phase(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-vibeMTmt0*_mt-off_part-phase_MPM.nii.gz'))

#remove acquisition string from file names
rule copy_raw_qsm:
    input:
        check_csa_added_to_meta  
    output:
        directory("data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/")
    run: #python code, not shell
        qsm_folder = Path(str(output))
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
            shutil.copy(raw, qsm)
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)
        i=0
        for img in mag_list_clipped:
            i += 1
            raw = Path(img)
            qsm_name = wildcards.subject + "_" + wildcards.session + "_echo-" + str(i) + "_part-mag_MEGRE.nii.gz"
            qsm = qsm_folder / qsm_name
            shutil.copy(raw, qsm)
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)

rule qsmxt:
    input:
        "data/derivatives/{field_strength}/QSM/{subject}/{session}/anat/"
    output:
        directory("data/derivatives/{field_strength}/QSM/derivatives/workflow/qsmxt-workflow/{subject}/{session}/")    
    threads: 4
    resources:
        mem_mb=11000
    container:
        "docker://vnmd/qsmxt_8.2.2:20260105"
    shell:
        """
        qsmxt data/derivatives/{wildcards.field_strength}/QSM --auto_yes
        """