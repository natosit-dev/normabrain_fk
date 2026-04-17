snakemake --config input_dicoms_path="../test_dicoms" -np data/derivatives/3T/MPM/sub-rfl260123normanoel/ses-1/sub-rfl260123normanoel_ses-1_acq-vibeMT_T1map_registeredtoMP2RAGE.nii.gz --dag | sed -n "/digraph/,/}/p" | dot -Tsvg > qT1_dag.svg

#generate BIDS folder first
snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --sdm conda --cores 2 data/rawdata/bids/3T/code/bidscoin/fixmeta.log

#then run image processing
if command -v nvidia-smi; then
    #include nvidia arguments for singularity if GPU is available
    snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --resources mem_mb=10000 --sdm conda apptainer --cores 8 --singularity-args "--nv -e" --rerun-incomplete
else
    snakemake --config input_dicoms_path="/home/rflaherty/test_dicoms" protocol_path="/home/rflaherty/NORMA_DEV_CPP/" --resources mem_mb=9300 --sdm conda apptainer --cores 8 --rerun-incomplete
fi
