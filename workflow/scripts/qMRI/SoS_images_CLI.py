# ///////////////////////////////////////////////////////////////////////////////////////////////
# // L. SOUSTELLE, PhD, Aix Marseille Univ, CNRS, CRMBM, Marseille, France
# // Contact: lucas.soustelle@univ-amu.fr
# // Sum of squares of MGE data for SNR enhancement of 3D+mTE images
# ///////////////////////////////////////////////////////////////////////////////////////////////

import sys
import re
import os
import nibabel
import numpy
import subprocess


## load & SoS
in_niipaths = sys.argv[1].split(',')
SoS_niipath = sys.argv[2]
ref_nii     = nibabel.load(in_niipaths[0])

if len(in_niipaths) > 1: ## multiple 3D volumes case
    img_cat     = numpy.square(ref_nii.get_fdata()[:,:,:,numpy.newaxis])
    for ii in numpy.arange(1,len(in_niipaths)):
        img_tmp = numpy.square(nibabel.load(in_niipaths[ii]).get_fdata()[:,:,:,numpy.newaxis])
        img_cat = numpy.concatenate([img_cat,img_tmp],axis=3)
    img_cat = numpy.sum(img_cat,axis=3)
    img_SoS = numpy.sqrt(img_cat)
else:
    img_tmp = numpy.square(nibabel.load(in_niipaths[0]).get_fdata())
    img_tmp = numpy.sum(img_tmp,axis=3)
    img_SoS = numpy.sqrt(img_tmp)

## save
new_img = nibabel.Nifti1Image(img_SoS, ref_nii.affine, ref_nii.header)
nibabel.save(new_img, SoS_niipath)