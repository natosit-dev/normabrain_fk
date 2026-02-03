import json
import glob
def get_qMT_params(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mt0*_echo-1_flip-{wildcards.mtflip}_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        mt0map_meta = json.load(f)
        mt_params = {
            'mt_state' : mt0map_meta["mt_state"],
            'sat_pulse_ms' : mt0map_meta['sat_pulse_ms'],
            'interdelay_ms' : mt0map_meta['interdelay_ms'],
            'ro_pulse_ms' : mt0map_meta['ro_pulse_ms'],
            'tr_ms' : mt0map_meta['tr_ms'],
            'ro_fa_deg' : mt0map_meta['ro_fa_deg'],
            'ro_pulse_shape' : mt0map_meta['ro_pulse_shape'],
            'sat_pulse_fa_deg' : mt0map_meta['sat_pulse_fa_deg'],
            'sat_pulse_offset_hz' : mt0map_meta['sat_pulse_offset_hz'],
            'sat_pulse_shape' : mt0map_meta['sat_pulse_shape']
        }
    return mt_params

wildcard_constraints:
    run=".*", #run can be an empty string
    t1flip=r"\d+", #t1flip should be a number
    mtflip=r"\d+",
    pdflip=r"\d+"

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["VFA_contrasts"]]),
    seq = config["VFA_sequence"]

rule mtr:
    input:
        mt_off = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mt0_flip-{flip}_mt-off_part-mag_SoS_toREF{t1flip}.nii.gz",
        mt_on = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mtw_flip-{flip}_mt-on_part-mag_SoS_toREF{t1flip}.nii.gz"
    output:
        "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_flip-{flip}_toREF{t1flip}_MTRmap.nii.gz"
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
        build = directory("workflow/scripts/luca_qMT/build/"),
        mt_off = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mt0_flip-{mtflip}_mt-off_part-mag_SoS_toREF{t1flip}.nii.gz",
        mt_on = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}mtw_flip-{mtflip}_mt-on_part-mag_SoS_toREF{t1flip}.nii.gz",
        pdw = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}pdw_flip-{pdflip}_mt-off_part-mag_SoS_toREF{t1flip}.nii.gz",
        t1w = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_flip-{t1flip}_mt-off_part-mag_SoS.nii.gz",
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp{run}_smooth_reslicedto{seq}t1wMPM{t1flip}_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/VFA_preproc/{subject}/{session}/{subject}_{session}_acq-{seq}t1w_flip-{t1flip}_mt-off_part-mag_SoS_brain_mask.nii.gz"
    params:
        mt_params = get_qMT_params
    output:
        mpfmap = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_t1flip-{t1flip}_mtflip-{mtflip}_pdflip-{pdflip}_MPFmap{run}.nii.gz",
        t1map = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_t1flip-{t1flip}_mtflip-{mtflip}_pdflip-{pdflip}_T1map{run}.nii.gz",
        r1map = "data/derivatives/{field_strength}/qT1qMT/{subject}/{session}/{subject}_{session}_acq-{seq}_t1flip-{t1flip}_mtflip-{mtflip}_pdflip-{pdflip}_R1map{run}.nii.gz"
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
        --VFA_PARX {wildcards.pdflip},{wildcards.mtflip},{wildcards.t1flip},{params.mt_params[ro_pulse_shape]} \
        --MTw_PARX {params.mt_params[ro_fa_deg]},{params.mt_params[ro_pulse_shape]},{params.mt_params[sat_pulse_fa_deg]},{params.mt_params[sat_pulse_offset_hz]},{params.mt_params[sat_pulse_shape]} \
        --B1 {input.b1map} \
        --mask {input.mask} \
        --nworkers {threads} \
        --cpp_opt
        """