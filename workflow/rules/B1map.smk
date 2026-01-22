rule smooth_B1:
    input:
        "data/{field_strength}/rawdata/bids/{subject}/{session}/fmap/{subject}_{session}_acq-famp_TB1TFL.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/B1map/SmoothImage/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        SmoothImage 3 {input} 3x1x1 {output}
        """

rule reslice_B1:
    input:
        b1map = "data/{field_strength}/derivatives/B1map/SmoothImage/{subject}/{session}/{subject}_{session}_acq-famp_smooth.nii.gz",
        ref = "data/{field_strength}/derivatives/MPM_preproc/SoS_images_CLI/{subject}/{session}/{subject}_{session}_acq-{seq}t1w{acq}_flip-25_mt-off_part-mag_SoS.nii.gz"
    output:
        temp("data/{field_strength}/derivatives/B1map/antsApplyTransforms/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w{acq}MPM.nii.gz")
    conda:
        "../envs/ants.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -r {input.ref} -i {input.b1map} -o {output}
        """
