import argparse
import json
from brainhack import Tukey, Sequence, Signal, System, Simulator, Corrector
from pathlib import Path
from nibabel import load, Nifti1Image


def ihmt_b1corr(ihmt_nifti: str, b1map_nifti: str, mask_nifti: str, map_type: str):
    #limit possible values of map_type
    assert map_type in ["MT0", "MTs_Positive", "MTs_Negative", "MTd_CM", "MTd_ALT", "MTs", "ihMT_CM", "ihMT_ALT", "BP", "MTsR_Positive", "MTsR_Negative", "MTsR", "MTdR_CM", "MTdR_ALT", "ihMTR_CM", "ihMTR_ALT", "BPR", "ALL"]
    #make file strings Paths
    ihmt_nifti = Path(ihmt_nifti)
    ihmt_json = ihmt_nifti.with_ext("").with_ext(".json")
    with open(ihmt_json, "r") as f:
        ihmt_meta = json.load(f)
    b1map_nifti = Path(b1map_nifti)
    mask_nifti = Path(mask_nifti)

    param_paths = {
        flipAngle: b1map_nifti,
        mask: mask_nifti
    }

    data_paths = {
        getattr(Signal, map_type): ihmt_nifti
    }

    param_maps = dict()
    data_maps = dict()

    affine, header = None, None

    for key, val in param_paths.items():
        param_maps[key] = load(val).get_fdata()

    param_maps['mask'] = param_maps['mask'].astype(bool)

    for key, val in data_paths.items():
        if affine is None or header is None:
            tmp = load(val)
            affine = tmp.affine
            header = tmp.header
            data_maps[key] = tmp.get_fdata()
    
    #parameters need to be converted to seconds and degrees
    pulse = Tukey(
        shape = ihmt_meta["TukeyShape"],
        duration = ihmt_meta["PulseDuration_us"] * 1e-6,
        offset = ihmt_meta["FrequencyOffset_hz"],
        flipAngle = ihmt_meta["FlipAngle_deg"],
    )

    seq = Sequence(
        signal = Signal.ALL,
        pulse = pulse,
        N_pulsePerOffset=1,
        N_pulse = ihmt_meta["NumberPulses"],
        N_burst = ihmt_meta["NumberBursts"],
        N_adc = ihmt_meta["TurboFactor"],
        N_dummyADC = ihmt_meta["DummyEchoes"],
        dt_interPulse = ihmt_meta["PulseRepetitionTime_us"] * 1e-6,
        TR_burst = ihmt_meta["BurstRepetitionTime_us"] * 1e-6,
        dt_lastBurst = (ihmt_meta["TotalPrepDuration_us"] * 1e-6) - (ihmt_meta["BurstRepetitionTime_us"] * 1e-6 * (ihmt_meta["NumberBursts"] - 1)),
        es = 
    )