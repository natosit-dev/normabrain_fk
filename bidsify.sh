#first copy the DICOMS to the project directory based on field strength
python3 copy_dicoms_field_strength.py ../test_dicoms .
#generate the bidsmap for the dicom data
bidsmapper ../test_dicoms/ bids/ -t ./bidsmap_normabrain_template -n '*' -m '*' -a
#edit the bidsmap manually in the GUI
# bidseditor bids/ -t ./bidsmap_normabrain_template
#then convert the dicoms to nifti and organize into BIDS structure using the bidsmap
bidscoiner ../test_dicoms/ ./bids/
python3 add_csa_data_to_meta.py