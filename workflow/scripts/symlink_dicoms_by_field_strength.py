import argparse
import os
import pydicom
from pathlib import Path
from bidscoin import lsdirs

def symlink_dicoms_by_field_strength(source_dicoms_folder: str, output_folder: str, subject_list="*"):
    # Convert source folder to Path object
    rawfolder = Path(source_dicoms_folder).resolve()
    
    # List subjects folders, assuming they are the next directories in the hierarchy
    subjects = []
    if subject_list != "*" :
        for sub in subject_list:
            subject_folder = lsdirs(rawfolder, sub)[0]
            subjects.append(subject_folder)
    else:
        subjects = lsdirs(rawfolder, '*')

    #loop through the subjects folders
    for subject in subjects:
        # List session folders within each subject, assuming they are the next directories in the hierarchy
        sessions = lsdirs(subject, '*')
        
        i=0
        #Loop through the sessions folders
        for session in sessions:
            print(session)
            i=i+1 #change session name from date to index
            # Read the first DICOM file to get the field strength
            first_dicom_path = list(session.rglob('*.dcm'))[0]
            first_dicom = pydicom.dcmread(first_dicom_path)
            if isinstance(first_dicom[0x18, 0x87].value, str):
                field_value = str(first_dicom[0x18, 0x87].value)
            else:
                first_dicom_path = list(session.rglob('*.dcm'))[1]
                first_dicom = pydicom.dcmread(first_dicom_path)
                field_value = str(first_dicom[0x18, 0x87].value)
            
            # Create new folder path based on field strength
            new_folder = Path(os.path.join(output_folder, field_value + 'T', 'sub-' + subject.name, 'ses-' + str(i)))
            if not os.path.exists(new_folder):
                os.makedirs(new_folder)
            
            #symlink the contents of the session folder to the new location
            for item in os.listdir(session):
                if not os.path.exists(os.path.join(new_folder, item)):
                    os.symlink(os.path.join(session, item), os.path.join(new_folder, item))

            #remove dicoms with NoAV in the name
            for dicom in list(new_folder.rglob('*NoAV*.dcm', recurse_symlinks=True)):
                os.remove(dicom.parent)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Symlink DICOM files to new folders based on their magnetic field strength")
    parser.add_argument('source_dicoms_folder', type=str, help="Path to the source DICOM folder")
    parser.add_argument('output_folder', type=str, help="Path to the output folder where 3T and 7T folders will be created and DICOMS copied")
    parser.add_argument('subject_list', nargs="*", type=str, default="*", help="Space separated list of subject folder names. Default is all subject folders in the source DICOM folder.")
    args = parser.parse_args()
    symlink_dicoms_by_field_strength(args.source_dicoms_folder, args.output_folder, args.subject_list)