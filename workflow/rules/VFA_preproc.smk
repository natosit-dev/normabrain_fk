#generate a dataframe of all subject/session paths
# import pandas as pd
# paths_df = pd.DataFrame(columns=["subject", "session", "field_strength", "session_path"])
# session_paths = []
# for strength in FIELD_STRENGTHS:
#     bids_path = data_path / strength / "bids"
#     subject_paths = [x for x in bids_path.glob('sub-*') if x.is_dir()]
#     for subject in subject_paths:
#         sessions = [x for x in subject.glob("ses-*") if x.is_dir()]
#         session_paths = [*session_paths, *sessions]
#         subject = subject.name
#         for session in sessions:
#             session_name = session.name
#             session_series = pd.Series({
#                 "subject": subject,
#                 "session": session_name,
#                 "field_strength": strength,
#                 "session_path": session
#             })
#             paths_df = pd.concat([paths_df, pd.DataFrame([session_series])], ignore_index=True)


import glob

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["VFA_contrasts"]]),
    seq = config["VFA_sequence"],

def get_echos(wildcards):
    return glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}*_echo-*_flip-*_mt-{wildcards.mt}_part-{wildcards.part}_MPM.nii.gz')[:config["n_echos"]]

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

#rule concat echos for each contrast
#then run new SoS script on these
rule SoS:
    input:
        # meta_complete = check_csa_added_to_meta,
        echos = get_echos
    params:
        files=lambda wildcards, input: ','.join(input.echos)
    output:
       "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    conda:
        "../envs/qMT.yaml"
    threads: 2
    shell:
        """
        python3 workflow/scripts/SoS_images_CLI.py {params.files} {output}
        """


rule synthstrip:
    input:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain.nii.gz"),
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 4
    shell:
        """
        mri_synthstrip -i {input} -o {output[0]} -m {output[1]} -t {threads} --no-csf
        """


rule DenoiseImage:
    input:
        input_image = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection:
    input:
        input_image = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """


rule register_MPM_to_t1w:
    input:
        ref = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_brain_denoised_n4_registeredto{seq}t1w.nii.gz"),
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_denoised_n4_registeredto{contrast}{mt}{part}.nii.gz"),
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_Composite.h5",
        temp("data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_InverseComposite.h5")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsRegistration --verbose 1 --dimensionality 3 --float 0 --write-composite-transform 1 --collapse-output-transforms 1 --output [ data/derivatives/{wildcards.field_strength}/VFA_preproc/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}_mt-{wildcards.mt}_part-{wildcards.part}_registeredto{wildcards.seq}t1w_, {output[0]}, {output[1]} ] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] --initial-moving-transform [ {input.ref}, {input.moving}, 1 ] --transform Rigid[ 0.1 ] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-6, 50 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 4x2x1x0vox --masks [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """
  
        
rule apply_reg_MPM_to_ref:
    input:
        moving = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS.nii.gz",
        ref = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS.nii.gz",
        reg = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_Composite.h5"
    output:
        "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_SoS_registeredto{seq}t1w.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -n Linear -i {input.moving} -r {input.ref} -t {input.reg} -o {output}
        """
