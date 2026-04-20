import glob

def get_dwi_nii(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-*{wildcards.dwi_params}*_dir-PA_dwi.nii.gz'))

def get_b0_nii(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-*b0*{wildcards.dwi_params}*_dir-AP_dwi.nii.gz'))

rule nyu_designer:
    input:
        dwi=get_dwi_nii,
        b0=get_b0_nii
    params:
        preproc="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_preproc/"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dwi_designer.nii.gz"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    threads:
        8
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{dwi_params}_dwi_designer.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        designer "{input.dwi}" "{output}" -denoise -shrinkage frob -adaptive_patch -rician -degibbs -eddy -rpe_pair $HOME/{input.b0} -normalize -mask -scratch {params.preproc} -nocleanup -n_cores {threads}
        """