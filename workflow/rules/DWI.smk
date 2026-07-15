import glob
import os
from pathlib import Path

bidspath = Path("data/rawdata/bids")
try:
    field_strength_list=next(os.walk(bidspath))[1]
except:
    field_strength_list=[]

def get_dwi_mag_nii(wildcards):
    #try filename with part-mag first, then use more generic name
    try:
        dwi_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-mag_*dwi.nii.gz'))[0]
        dwi_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-mag_*dwi.nii.gz'))
    except:
        dwi_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_*dwi.nii.gz'))[0]    
        dwi_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_*dwi.nii.gz'))
    return dwi_mag

def get_dwi_phase_nii(wildcards):
    dwi_phase = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-phase_*dwi.nii.gz'))
    return dwi_phase

def get_dwi_phase_mif(wildcards):
    dwi_phase = sorted(glob.glob(f'data/derivatives/{wildcards.field_strength}/dwi/sub-{wildcards.subject}/ses-{wildcards.session}/acq-DWI{wildcards.dwi_params}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-DWI{wildcards.dwi_params}_dir-PA_part-phase_dwi.mif'))
    return dwi_phase

def get_b0_mag_nii(wildcards):
    #try filename with part-mag first, then use more generic name
    try:
        b0_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_part-mag_*dwi.nii.gz'))[0]
        b0_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_part-mag_*dwi.nii.gz'))
    except:
        b0_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_*dwi.nii.gz'))[0]    
        b0_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_*dwi.nii.gz'))
    return b0_mag

def aggregate_dki(wildcards):
    layout=layout_dict[wildcards.field_strength]
    dki_list = []
    subjectlist = layout.get_subject(suffix="dwi")
    for subject in subjectlist:
        sessionlist = layout.get_session(suffix="dwi", subject=subject)
        for session in sessionlist:
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for dwi in dwi_acqlist:
                # dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                dki_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + dwi + "/dki/")
    return dki_list

rule concat_dwi_runs:
    input:
        dwi=get_dwi_mag_nii,
        b0=get_b0_mag_nii,
        phase=get_dwi_phase_nii
    output:
        dwi="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-mag_dwi.mif",
        b0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-AP_part-mag_dwi.mif",
    params:
        phase_out="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-phase_dwi.mif"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/preproc/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_concatenate.log",
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export input_dwi=({input.dwi})
        dwi_tmp=()
        if [ ${{#input_dwi[@]}} -gt 1 ]; then
            for img in "${{input_dwi[@]}}"; do
                mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                dwi_tmp+=("${{img%.nii.gz}}.mif")
            done
            mrcat ${{dwi_tmp[@]}} {output.dwi} -force
            for img in "${{dwi_tmp[@]}}"; do
                rm $img
            done
        else
            mrconvert -json_import "${{input_dwi%.nii.gz}}.json" -fslgrad "${{input_dwi%.nii.gz}}.bvec" "${{input_dwi%.nii.gz}}.bval" -force {input.dwi} {output.dwi}
        fi
        
        export input_b0=({input.b0})
        b0_tmp=()
        if [ ${{#input_b0[@]}} -gt 1 ]; then
            for img in "${{input_b0[@]}}"; do
                mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                b0_tmp+=("${{img%.nii.gz}}.mif")
            done
            mrcat ${{b0_tmp[@]}} {output.b0} -force
            for img in "${{b0_tmp[@]}}"; do
                rm $img
            done
        else
            mrconvert -json_import "${{input_b0%.nii.gz}}.json" -fslgrad "${{input_b0%.nii.gz}}.bvec" "${{input_b0%.nii.gz}}.bval" -force {input.b0} {output.b0}
        fi
 
        export input_phase=({input.phase})
        phase_tmp=()
        if [ ${{#input_phase[@]}} -gt 0 ]; then
            if [ ${{#input_phase[@]}} -gt 1 ]; then
                for img in "${{input_phase[@]}}"; do
                    mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                    phase_tmp+=("${{img%.nii.gz}}.mif")
                done
                mrcat ${{phase_tmp[@]}} {params.phase_out} -force
                for img in "${{phase_tmp[@]}}"; do
                    rm $img
                done
            else
                mrconvert -json_import "${{input_phase%.nii.gz}}.json" -fslgrad "${{input_phase%.nii.gz}}.bvec" "${{input_phase%.nii.gz}}.bval" -force {input.phase} {params.phase_out}
            fi
        fi       
        """


rule nyu_designer:
    input:
        dwi="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-mag_dwi.mif",
        b0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-AP_part-mag_dwi.mif",
        phase=get_dwi_phase_mif
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
        if command -v eddy_cuda >/dev/null 2>&1; then
            export PATH="$(dirname "$(command -v eddy_cuda)"):$PATH"
        fi
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi

        echo "BZeroThreshold: 15.0" > $HOME/.mrtrix.conf
        if [ {input.phase} ]; then
            designer "{input.dwi}" "{output.mif}" \
            -denoise -shrinkage frob -adaptive_patch -phase $HOME/{input.phase} \
            -degibbs \
            -eddy -rpe_pair $HOME/{input.b0} -eddy_quad_off \
            -normalize \
            -scratch {params.preproc} -nocleanup \
            -n_cores {threads} -nthreads {threads}
        else
            designer "{input.dwi}" "{output.mif}" \
            -denoise -shrinkage frob -adaptive_patch -rician \
            -degibbs \
            -eddy -rpe_pair $HOME/{input.b0} -eddy_quad_off \
            -normalize \
            -scratch {params.preproc} -nocleanup \
            -n_cores {threads} -nthreads {threads}
        fi
        
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
        python workflow/scripts/dki_tensor_dipy.py {input.img} {input.mask} {params.outprefix}
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
        expand("data/derivatives/{field_strength}/dwi/dki.done", field_strength=field_strength_list)
