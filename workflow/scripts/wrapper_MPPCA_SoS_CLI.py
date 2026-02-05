# ///////////////////////////////////////////////////////////////////////////////////////////////
# // L. SOUSTELLE, PhD, Aix Marseille Univ, CNRS, CRMBM, Marseille, France
# // Contact: lucas.soustelle@univ-amu.fr
# // 4D images MP-PCA & SoS tool
# ///////////////////////////////////////////////////////////////////////////////////////////////

import sys
import re
import os
import nibabel
import numpy
import subprocess
import tempfile
import shutil
import argparse; from argparse import RawTextHelpFormatter

def main():
    # parse arguments
    text_description = "Denoise MP-PCA (MRtrix3 package) & sum-of-squares (multi-GRE case only).\
                        Assumes that all volumes in the multi-GRE case have the same total number of echoes" 
    parser = argparse.ArgumentParser(description=text_description,formatter_class=RawTextHelpFormatter)
    parser.add_argument('INPUT_NIIS',   nargs="+",help="Input NIfTI images path(s) (comma-separated)")
    parser.add_argument('--SUFFIX_NII', type=str,help="Unique suffix for NIfTI image paths")
    parser.add_argument('--OUT_DIR',    type=str,help="Directory of output images (default: same as inputs)")
    parser.add_argument('--MPPCA',      action='store_true',help="Toggle MP-PCA denoising")
    parser.add_argument('--N_SoS',      type=int,help="Number of echoes to SoS (should be <= min. total number of echoes)")
    parser.add_argument('--nthreads',   type=int,help="Number of threads for MP-PCA routine (dwidenoise -nthreads)")
    
    args        = parser.parse_args()
    IN_NIIS     = [','.join(args.INPUT_NIIS)] # ensure it's a comma-separated list
    SUFFIX_NII  = args.SUFFIX_NII
    N_SoS       = args.N_SoS

    # check & concatenate all niis
    niipaths    = IN_NIIS[0].split(',')
    ref_nii     = nibabel.load(niipaths[0])
    
    ## determine control SoS parx (if any)
    if args.N_SoS is not None:
        N_SoS = args.N_SoS 
    else:
        N_SoS = 1
    if N_SoS <= 0:
        parser.error('--N_SoS should be >= 1')
    
    if args.nthreads is None:
        nthreads = 1
    else:
        nthreads = args.nthreads

    ## concatenate
    img_cat     = ref_nii.get_fdata()
    for ii in numpy.arange(1,len(niipaths)): # 1:numel(volumes) because first volume 'ref' is already loaded
        img_cat = numpy.concatenate([img_cat,nibabel.load(niipaths[ii]).get_fdata()],axis=3)

    # MP-PCA denoising
    if args.MPPCA:
        print('Running MP-PCA over concatenated volumes ...')
        tmp_path        = tempfile.mkdtemp()
        MPPCA_niipath   = os.path.join(tmp_path,'MPPCA.nii.gz')
        new_nii         = nibabel.Nifti1Image(img_cat, ref_nii.affine, ref_nii.header)
        nibabel.save(new_nii, MPPCA_niipath)
        bashCommand     = ['dwidenoise', '-nthreads', str(nthreads), '-f', MPPCA_niipath, MPPCA_niipath]
        subprocess.call(bashCommand)
        img_cat         = nibabel.load(MPPCA_niipath).get_fdata()
        shutil.rmtree(tmp_path) # delete temporary folder
    
    # SoS & save img
    img_IDX = 0
    for ii in numpy.arange(len(niipaths)):
        N_MGE   = nibabel.load(niipaths[ii]).shape[3]
        if N_MGE < N_SoS:
            parser.error('Number of gradient echo in image < N_SoS; please adjust --N_SoS option')

        img_SoS = numpy.square(img_cat[:,:,:,img_IDX:img_IDX+N_SoS])
        img_SoS = numpy.sum(img_SoS,axis=3)
        img_SoS = numpy.sqrt(img_SoS)
        new_nii = nibabel.Nifti1Image(img_SoS, nibabel.load(niipaths[ii]).affine, nibabel.load(niipaths[ii]).header)
            
        # control output directory
        if args.OUT_DIR is not None:
            nibabel.save(new_nii, args.OUT_DIR+os.path.basename(re.sub(r"\.nii(\.gz)?$", SUFFIX_NII, niipaths[ii])))
        else:
            nibabel.save(new_nii, re.sub(r"\.nii(\.gz)?$", SUFFIX_NII, niipaths[ii]))

        # get ready for next image
        img_IDX = img_IDX + N_MGE


#### main
if __name__ == "__main__":
    # sys.argv = ['DEN_MPPCA_SoS.py', 
    #             '22_vibeMTv2p4_c32_Df30_FA10.nii,21_vibeMTv2p4_c32_Df25_FA10.nii',
    #             '--N_SoS', '2']
    
    sys.exit(main()) 