snakemake --config input_dicoms_path="../test_dicoms" -np results/3T/qT1qMT/sub-rfl260123normanoel/ses-1/sub-rfl260123normanoel_ses-1_acq-vibeMTsag1isoc9_t1flip-33_mtflip-14_pdflip-6_MPFmap_run-1.nii.gz --dag | sed -n "/digraph/,/}/p" | dot -Tsvg > MPFmap_dag.svg

snakemake --config input_dicoms_path="../test_dicoms" --sdm conda --cores 2 results/add_csa_data_to_meta_3T.complete
snakemake --config input_dicoms_path="../test_dicoms" --sdm conda --cores 2