import json
import glob
def get_qMT_params(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mt0*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        mt0_meta = json.load(f)
        mt_params = {
            'mtflip' : mt0_meta["FlipAngle"],
            'sat_pulse_ms' : mt0_meta['sat_pulse_ms'],
            'interdelay_ms' : mt0_meta['interdelay_ms'],
            'ro_pulse_ms' : mt0_meta['ro_pulse_ms'],
            'tr_ms' : mt0_meta['tr_ms'],
            'ro_fa_deg' : mt0_meta['ro_fa_deg'],
            'ro_pulse_shape' : mt0_meta['ro_pulse_shape'],
            'sat_pulse_fa_deg' : mt0_meta['sat_pulse_fa_deg'],
            'sat_pulse_offset_hz' : mt0_meta['sat_pulse_offset_hz'],
            'sat_pulse_shape' : mt0_meta['sat_pulse_shape']
        }
    return mt_params

def get_t1flip(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}t1w*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        t1w_meta = json.load(f)
    return t1w_meta["FlipAngle"]

def get_pdflip(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}pdw*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        pdw_meta = json.load(f)
    return pdw_meta["FlipAngle"]


wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["VFA_contrasts"]]),
    seq = config["VFA_sequence"]

rule mtr:
    input:
        mt_off = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_SoS_toREF.nii.gz",
        mt_on = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_SoS_toREF.nii.gz"
    output:
        "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_MTRmap.nii.gz"
    conda:
        "../envs/ants.yaml"
    shell:
        """
        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        """

rule setup_fit_JSPqMT_CLI:
    output:
        directory("workflow/scripts/luca_qMT/build/")
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        cd workflow/scripts/luca_qMT/
        python3 setup.py build_ext --inplace
        """


rule fit_JSPqMT_CLI:
    input:
        build = "workflow/scripts/luca_qMT/build/",
        mt_off = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_SoS_toREF.nii.gz",
        mt_on = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_SoS_toREF.nii.gz",
        pdw = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_SoS_toREF.nii.gz",
        t1w = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS.nii.gz",
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_smooth_reslicedto{seq}t1w_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_SoS_brain_mask.nii.gz"
    params:
        mt_params = get_qMT_params,
        t1flip = get_t1flip,
        pdflip = get_pdflip
    output:
        mpfmap = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_MPFmap.nii.gz",
        t1map = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        r1map = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_R1map.nii.gz"
    threads: 8
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        python3 workflow/scripts/luca_qMT/fit_JSPqMT_CLI.py \
        {input.mt_off},{input.mt_on} \
        {input.pdw},{input.mt_off},{input.t1w} \
        {output.mpfmap} \
        {output.t1map} \
        --R1f {output.r1map} \
        --MTw_TIMINGS {params.mt_params[sat_pulse_ms]},{params.mt_params[interdelay_ms]},{params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_TIMINGS {params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_PARX {params.pdflip},{params.mt_params[mtflip]},{params.t1flip},{params.mt_params[ro_pulse_shape]} \
        --MTw_PARX {params.mt_params[ro_fa_deg]},{params.mt_params[ro_pulse_shape]},{params.mt_params[sat_pulse_fa_deg]},{params.mt_params[sat_pulse_offset_hz]},{params.mt_params[sat_pulse_shape]} \
        --B1 {input.b1map} \
        --mask {input.mask} \
        --nworkers {threads} \
        --cpp_opt
        """