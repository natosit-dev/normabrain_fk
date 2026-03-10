This repository utilizes git submodules. To clone, use the command git clone --recurse-submodules <project url>

Requires: python3, conda, singularity, gcc

Installation: conda env create -f workflow/envs/snakemake.yaml
If installation from snakemake.yaml leads to conflicts, try running `conda config --set channel_priority strict` first