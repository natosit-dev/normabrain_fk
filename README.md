This repository utilizes git submodules. To clone, use the command git clone --recurse-submodules project_url

Requires: python3, conda, singularity, gcc


Installation: conda env create -f workflow/envs/snakemake.yaml

If installation from snakemake.yaml leads to conflicts, try running `conda config --set channel_priority flexible` first.

Some freesurfer tools require a freesurfer license. You can obtain a freesurfer license from https://surfer.nmr.mgh.harvard.edu/registration.html. Once you have obtained a license, save it to .snakemake/scripts