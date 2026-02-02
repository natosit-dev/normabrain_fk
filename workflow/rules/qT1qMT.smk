configfile: "config/snakemake_config.yaml"

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"]

rule mtr:
    input:
        mt_off = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mt0{acq}_flip-{flip}_mt-off_part-mag_SoS_toREF{t1flip}.nii.gz",
        mt_on = "results/{field_strength}/MPM_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mtw{acq}_flip-{flip}_mt-on_part-mag_SoS_toREF{t1flip}.nii.gz"
    output:
        "results/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}{acq}_flip-{flip}_toREF{t1flip}_MTR.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        """
