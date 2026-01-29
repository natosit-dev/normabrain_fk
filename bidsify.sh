#first copy the DICOMS to the project directory based on field strength
python3 workflow/scripts/copy_dicoms_by_field_strength.py ../test_dicoms data/
#generate the bidsmap for the dicom data
bidsmapper ./3T/rawdata/dicoms/ ./3T/rawdata/bids/ -t ./config/bidsmap_normabrain_template -n '*' -m '*' -a
#edit the bidsmap manually in the GUI
# bidseditor bids/ -t ./bidsmap_normabrain_template
#then convert the dicoms to nifti and organize into BIDS structure using the bidsmap
bidscoiner ./3T/rawdata/dicoms/ ./3T/rawdata/bids/
python3 workflow/scripts/add_csa_data_to_meta.py ./3T/rawdata/bids/

snakemake --config input_dicoms_path="../test_dicoms" --sdm conda --cores 2 results/add_csa_data_to_meta_3T.complete
snakemake --config input_dicoms_path="../test_dicoms" --sdm conda --cores 2
