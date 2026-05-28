# Installation

This repository utilizes git submodules. To clone, use the command ```git clone --recurse-submodules project_url```

Requires: python3, conda, singularity, gcc, dc, bc, bash


Once the repository is cloned, it can be installed with the command ```conda env create -f workflow/envs/snakemake.yaml```. To use the pipeline, first activate the environment with ```conda activate snakemake```.

If installation from snakemake.yaml leads to conflicts, try running ```conda config --set channel_priority flexible``` first.

Some freesurfer tools require a freesurfer license. You can obtain a freesurfer license from https://surfer.nmr.mgh.harvard.edu/registration.html. Once you have obtained a license, save it to ```.snakemake/scripts/.license```

ihMT MoCo also requires a license agreement. Please sign the license agreement and download the code at https://crmbm.univ-amu.fr/resources/ihmt-moco/. Once you have obtained the code, save it to ```.snakemake/scripts/ihMT_MoCo.sh```

# Useage

See ```run_workflow.sh``` for example useage. The pipeline is called with the Snakemake CLI, see https://snakemake.readthedocs.io/en/stable/ for documentation. Snakemake must be called with ```--sdm conda apptainer``` and the number of cores must be defined with ```--cores```. 

The raw DICOMS must first be organized into BIDS via the command ```snakemake--sdm conda --cores 2 data/rawdata/bids/{field_strength}/code/bidscoin/fixmeta.log``` for each field strength before the rest of the pipeline can be run. The template bidsmap used to organize raw DICOMS into BIDS can be edited at ```config/bidsmap_normabrain_template.yaml```.

To use GPU, add the argument ```--singularity-args "--nv -e"```. To limit memory useage in MB, use the argument ```--resources mem_mb=...```. 

The following variables are defined either in ```config/snakemake_config.yaml``` or via the CLI after the ```--config``` argument:
- ```input_dicoms_path``` (REQUIRED: path to the raw DICOMS from the scanner)
- ```protocol_path``` (REQUIRED: path to the scanning protocol xml files)
- ```MPM_sequence``` (REQUIRED: the base name of the qMT sequence used in the ProtocolName, "vibeMT" for NormaBRAIN)
- ```MPM_contrasts``` (REQUIRED: the bracketed comma-separated list of contrasts collected for the MPM sequence as described in the ProtocolName, ["mt0", "mtw", "pdw", "t1w"] for NormaBRAIN)
- ```subject_list_dicom``` (OPTIONAL: the space-separated list of subject folders in input_dicoms_path to include in the analysis. Default is all folders.)

By default, all subjects and sub-pipelines are run, as defined by the input files of "rule all" in ```workflow/Snakefile```. If you wish to only run a single subject or sub-pipeline, place the name of the target file at the end of the Snakemake command. For example, to generate freesurfer segmentation and mean ROI statistics for just the ihMT LoSar acquisition for subject 002 session 1 at 3T, run ```snakemake --resources mem_mb=9300 --sdm conda apptainer --cores 8 "data/derivatives/3T/freesurfer/sub-002_ses-1_acq-ihMTLoSar/stats/ihmt_stats.done"```. Snakemake will automatically also run the required MP2RAGE and B1map sub-pipelines, along with the ihMT sub-pipeline, for this field strength/subject/session to generate the segmentations.
