from dipy.core.gradients import gradient_table
from dipy.data import get_fnames
from dipy.io.gradients import read_bvals_bvecs
from dipy.io.image import load_nifti, save_nifti
import dipy.reconst.dki as dki
from dipy.reconst.weights_method import simple_cutoff, weights_method_wls_m_est

import argparse
import numpy as np
from pathlib import Path

def GMM_weights(*args):
    """Geman-McClure weights with outliers defined by +/-3 standard
    deviations.
    """
    return weights_method_wls_m_est(
        *args, m_est="gm", cutoff=3, outlier_condition_func=simple_cutoff
    )

def dki_tensor(preproc_nii: str, mask_nii: str, outprefix: str):
    #load the preprocessed dwi nii
    data, affine = load_nifti(preproc_nii)
    #load bval and bvec files
    bval_path = Path(preproc_nii).with_suffix("").with_suffix(".bval")
    bvec_path = Path(preproc_nii).with_suffix("").with_suffix(".bvec")
    bvals, bvecs = read_bvals_bvecs(bval_path, bvec_path)
    #convert bvals and bvecs into GradientTable object needed for dipy data recon
    gtab = gradient_table(bvals, bvecs=bvecs)
    #load the mask
    mask, affine = load_nifti(mask_nii)

    #define the model and fitting method
    dkimodel_unconstrained = dki.DiffusionKurtosisModel(gtab, fit_method="RWLS", num_iter=6)
    dkifit_unconstrained = dkimodel_unconstrained.fit(data, mask=mask)
    dkimodel_constrained = dki.DiffusionKurtosisModel(
    gtab, fit_method="CWLS", return_S0_hat=True, weights_method=GMM_weights, num_iter=6)
    dkifit_constrained = dkimodel_constrained.fit(data, mask=mask)

    #save maps calculated from the DKI tensor
    array_maps = ['fa', 'color_fa', 'md', 'rd', 'ad', 'kfa'] #attributes return an array
    func_maps = ['mk', 'rk', 'ak', 'mkt', 'rtk'] #attributes return a function, which returns an array
    for m in array_maps:
        save_nifti(outprefix + "unconstrained_" + m + ".nii.gz", getattr(dkifit_unconstrained, m), affine)
        save_nifti(outprefix + "constrained_" + m + ".nii.gz", getattr(dkifit_constrained, m), affine)
    for m in func_maps: #use () after getattr to call function to generate array
        save_nifti(outprefix + "unconstrained_" + m + ".nii.gz", getattr(dkifit_unconstrained, m)(), affine)
        save_nifti(outprefix + "constrained_" + m + ".nii.gz", getattr(dkifit_constrained, m)(), affine)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Fit constrained and unconstrained DKI models with iterative robust weighted least squares as described in Coveney et al. 2025, Coveney et al. 2026, and version 1.12.0 of the DIPY DKI tutorial. 
        In the constrained model the tensors are forced to be non-negative as described by Haije et al. 2020.
        """)
    parser.add_argument('preproc_nii', type=str, help="Path to preprocessed DWIs")
    parser.add_argument('mask_nii', type=str, help="Path to mask")
    parser.add_argument('outprefix', type=str, help="Prefix for output images. Relative to current working directory.")
    args = parser.parse_args()
    dki_tensor(args.preproc_nii, args.mask_nii, args.outprefix)
