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
configfile: "config/snakemake_config.yaml"

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"],
    # t1flip = '|'.join([re.escape(x) for x in config["MPM_T1W_flip"]])


rule SoS:
    input:
        meta_complete = "results/add_csa_data_to_meta_{field_strength}.complete",
        echos = lambda wildcards: expand("data/rawdata/bids/{field_strength}/{subject}/{session}/anat/{subject}_{session}_acq-{seq}{contrast}{acq}_echo-{echo}_flip-{flip}_mt-{mt}_part-{part}_MPM.nii.gz",
            field_strength=wildcards.field_strength,
            subject=wildcards.subject,
            session=wildcards.session,
            seq=config["MPM_sequence"],
            contrast=wildcards.contrast,
            acq=wildcards.acq,
            flip=wildcards.flip,
            mt=wildcards.mt,
            part=wildcards.part,
            echo=glob_wildcards("data/rawdata/bids/{field_strength}/{subject}/{session}/anat/{subject}_{session}_acq-{seq}{contrast}{acq}_echo-{echo}_flip-{flip}_mt-{mt}_part-{part}_MPM.nii.gz").echo
        )
    params:
        files=lambda wildcards, input: ','.join(input.echos)
    output:
       "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS.nii.gz".strip("Pha").strip("Mag")
    conda:
        "../envs/qMT.yaml"
    threads: 2
    shell:
        """
        python3 workflow/scripts/qMT/SoS_images_CLI.py {params.files} {output}
        """


rule save_ref_SoS:
    input:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_mt-off_part-mag_SoS.nii.gz"
    output:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_SoS.nii.gz"
    shell:
        """
        cp {input} {output}
        """


rule synthstrip:
    input:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain.nii.gz"),
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz")
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_synthstrip -i {input} -o {output[0]} -m {output[1]} --no-csf
        """


rule save_ref_brainmask:
    input:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_mt-off_part-mag_SoS_brain_mask.nii.gz"
    output:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_brain_mask.nii.gz"
    shell:
        """
        cp {input} {output}
        """


rule DenoiseImage:
    input:
        input_image = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain.nii.gz",
        mask_image = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection:
    input:
        input_image = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz",
        mask_image = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised_n4.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

rule register_MPM_to_ref:
    input:
        ref = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_mt-off_part-mag_SoS_brain_denoised_n4.nii.gz",
        moving = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised_n4.nii.gz",
        ref_mask = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_brain_mask.nii.gz",
        moving_mask = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised_n4_toREF{t1flip}.nii.gz"),
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_mt-off_part-mag_SoS_brain_denoised_n4_to{contrast}{flip}{mt}{part}.nii.gz"),
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_toREF{t1flip}_Composite.h5",
        temp("results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_toREF{t1flip}_InverseComposite.h5")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsRegistration --verbose 1 --dimensionality 3 --float 0 --write-composite-transform 1 --collapse-output-transforms 1 --output [ results/{wildcards.field_strength}/MPM_preproc/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}{wildcards.acq}_flip-{wildcards.flip}_mt-{wildcards.mt}_part-{wildcards.part}_toREF{wildcards.t1flip}_, {output[0]}, {output[1]} ] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] --initial-moving-transform [ {input.ref}, {input.moving}, 1 ] --transform Rigid[ 0.1 ] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-6, 50 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 4x2x1x0vox --masks [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """
  
        
rule apply_reg_MPM_to_ref:
    input:
        moving = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS.nii.gz",
        ref = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-{t1flip}_reference_SoS.nii.gz",
        reg = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_toREF{t1flip}_Composite.h5"
    output:
        "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_toREF{t1flip}.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -n Linear -i {input.moving} -r {input.ref} -t {input.reg} -o {output}
        """

# apply B1 correction
# rule setup.py
# rule fit_JSPqMT_CLI.py