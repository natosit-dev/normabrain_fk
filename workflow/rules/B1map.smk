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