import argparse
import json
from brainhack import Tukey, Sequence, Signal, System, Simulator, Corrector
from pathlib import Path
from nibabel import load, Nifti1Image


def ihmt_b1corr(b1map_nifti: str, mask_nifti: str, meta_json: str, map_types*):
    for map_type in map_types:
        assert map_type in ["MT0", "MTs_Positive", "MTs_Negative", "MTd_CM", "MTd_ALT", "MTs", "ihMTmap_CM", "ihMTmap_ALT", "BP", "MTRs_Positive", "MTRs_Negative", "MTRs", "MTRd_CM", "MTRd_ALT", "ihMTR_CM", "ihMTR_ALT", "BPR", "ALL"]