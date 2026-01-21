#generate a dataframe of all subject/session paths
# import pandas as pd
# paths_df = pd.DataFrame(columns=["subject", "session", "field_strength", "session_path"])
# session_paths = []
# for strength in FIELD_STRENGTHS:
#     bids_path = data_path / strength / "rawdata" / "bids"
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

configfile: "config/snakemake_config.yaml"

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]])

rule SoS:
    input:
        meta_complete = "results/add_csa_data_to_meta_{field_strength}.complete",
        echos = lambda wildcards: expand("data/{field_strength}/rawdata/bids/{subject}/{session}/anat/{subject}_{session}_acq-{seq}{contrast}{acq}_echo-{echo}_flip-{flip}_mt-{mt}_part-{part}_MPM.nii.gz",
            field_strength=wildcards.field_strength,
            subject=wildcards.subject,
            session=wildcards.session,
            seq=config["MPM_sequence"],
            contrast=wildcards.contrast,
            acq=wildcards.acq,
            flip=wildcards.flip,
            mt=wildcards.mt,
            part=wildcards.part,
            echo=glob_wildcards("data/{field_strength}/rawdata/bids/{subject}/{session}/anat/{subject}_{session}_acq-{seq}{contrast}{acq}_echo-{echo}_flip-{flip}_mt-{mt}_part-{part}_MPM.nii.gz").echo
        )
    params:
        files=lambda wildcards, input: ','.join(input.echos)
    output:
       temp("data/{field_strength}/derivatives/MTRqT1qMT/SoS_images_CLI/{subject}/{session}/{subject}_{session}_acq-{seq}{contrast}{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS.nii.gz")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        python3 workflow/scripts/qMT/SoS_images_CLI.py {params.files} {output}
        """


rule synthstrip:
    input:
        "data/{field_strength}/derivatives/MTRqT1qMT/SoS_images_CLI/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/MTRqT1qMT/synthstrip/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain.nii.gz"),
        "data/{field_strength}/derivatives/MTRqT1qMT/synthstrip/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_synthstrip -i {input} -o {output[0]} -m {output[1]} --no-csf
        """

rule DenoiseImage:
    input:
        input_image = "data/{field_strength}/derivatives/MTRqT1qMT/synthstrip/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain.nii.gz",
        mask_image = "data/{field_strength}/derivatives/MTRqT1qMT/synthstrip/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/MTRqT1qMT/DenoiseImage/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection:
    input:
        input_image = "data/{field_strength}/derivatives/MTRqT1qMT/DenoiseImage/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised.nii.gz",
        mask_image = "data/{field_strength}/derivatives/MTRqT1qMT/synthstrip/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_mask.nii.gz"
    output:
        "data/{field_strength}/derivatives/MTRqT1qMT/N4BiasFieldCorrection/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-{flip}_mt-{mt}_part-{part}_SoS_brain_denoised_n4.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """

rule register_MPM_to_ref:
    input:
        ref = "data/{field_strength}/derivatives/MTRqT1qMT/N4BiasFieldCorrection/{subject}/{session}/{subject}_{session}_acq-{acq}_flip-25_mt-off_part-mag_SoS_brain_denoised_n4.nii.gz"
        