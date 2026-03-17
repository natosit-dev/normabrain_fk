snakemake --config input_dicoms_path="../test_dicoms" -np data/derivatives/3T/MPM/sub-rfl260123normanoel/ses-1/sub-rfl260123normanoel_ses-1_acq-vibeMT_T1map_registeredtoMP2RAGE.nii.gz --dag | sed -n "/digraph/,/}/p" | dot -Tsvg > qT1_dag.svg

# snakemake --config input_dicoms_path="../test_dicoms" --sdm conda --cores 2 results/add_csa_data_to_meta_3T.complete

if command -v nvidia-smi; then
    snakemake --config input_dicoms_path="/home/rflaherty/test_dicoms" --resources mem_mb=10000 --sdm conda apptainer --cores 8 --singularity-args "--nv -e" --rerun-incomplete
else
    snakemake --config input_dicoms_path="/home/rflaherty/test_dicoms" --resources mem_mb=9300 --sdm conda apptainer --cores 8 --rerun-incomplete
fi
