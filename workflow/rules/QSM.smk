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
        for img in raw_list:
            raw = Path(img)
            qsm = qsm_folder / raw.name
            qsm = qsm.with_stem(qsm.stem.replace("_MPM", "_MEGRE"))
            shutil.copy(raw, qsm)
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)