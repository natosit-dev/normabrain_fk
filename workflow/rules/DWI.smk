import glob
from pathlib import Path

bidspath = Path("data/rawdata/bids")

def get_dwi_nii(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-*{wildcards.dwi_params}*_dir-PA_dwi.nii.gz'))

def get_b0_nii(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-*b0*{wildcards.dwi_params}*_dir-AP_dwi.nii.gz'))

def aggregate_dki(wildcards):
    layout=layout_dict[wildcards.field_strength]
    dki_list = []
    subjectlist = layout.get_subject(suffix="dwi")
    for subject in subjectlist:
        sessionlist = layout.get_session(suffix="dwi", subject=subject)
        for session in sessionlist:
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for dwi in dwi_acqlist:
                dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "")
                dki_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + dwi + "/dki/sub-" + subject + "_ses-" + session + "_acq-DWI" + dwi + "_rtk.nii.gz")
    return dki_list

rule nyu_designer:
    input:
        dwi=get_dwi_nii,
        b0=get_b0_nii
    params:
        preproc="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/preproc/"
    output:
        mif="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif",
        noisemap="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_noisemap.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    threads:
        8
    resources:
        mem_mb=11000
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        rm -rf {params.preproc}
        designer "{input.dwi}" "{output.mif}" -denoise -shrinkage frob -adaptive_patch -rician -degibbs -eddy -rpe_pair $HOME/{input.b0} -normalize -mask -scratch {params.preproc} -nocleanup -n_cores {threads} -nthreads {threads}
        cp {params.preproc}/sigma.nii {output.noisemap}
        rm -rf {params.preproc}
        """


rule convert_designer_mif_to_nii:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif"
    output:
        nii="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.nii.gz",
        json="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.json",
        bvec="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.bvec",
        bval="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.bval"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_convert_designer_mif_to_nii.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrconvert -force -stride -1,2,3,4 -json_export {output.json} -export_grad_fsl {output.bvec} {output.bval} {input} {output.nii}
        """


rule mean_b0:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif"
    output:
        b0=temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_b0.mif"),
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.log" 
    shell:
        """
        dwiextract -bzero {input} {output.b0}
        mrmath {output.b0} mean {output.meanb0} -axis 3
        """
    
rule b0_mask:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=8000
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} --no-csf -g || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_meanb0:
    input:
        img="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz",
        mask="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    output:
        temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.img} -mas {input.mask} {output}
        """


rule dki_tensor_dipy:
    input:
        img="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.nii.gz",
        mask="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    params:
        outprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_"
    output:
        directory("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/")
    conda:
        "../envs/dipy.yaml"
    resources:
        mem_mb=11000
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_dki.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mkdir -p {output}
        python3 workflow/scripts/dki_tensor_dipy.py {input.img} {input.mask} {params.outprefix}
        """

rule aggregate_dki_by_field_strength:
    input:
        aggregate_dki
    output:
        "data/derivatives/{field_strength}/dwi/dki.done"
    log:
        "logs/{field_strength}/dwi/dki.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """

rule aggregate_dki:
    input:
        expand("data/derivatives/{field_strength}/dwi/dki.done", field_strength=next(os.walk(bidspath))[1])
