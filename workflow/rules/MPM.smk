import json
import glob

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["MPM_contrasts"]]),
    seq = config["MPM_sequence"],
    part = 'mag|phase'

def check_csa_added_to_meta(wildcards):
    return checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]

def get_echos(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    #get the list of echo files and sort it
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}*_echo-*_flip-*_mt-{wildcards.mt}_part-{wildcards.part}_MPM.nii.gz'))

def get_qMT_params(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mtw*_echo-1_flip-*_mt-on_part-mag_MPM.json'))[0]
    with open(json_path, "r") as f:
        mtw_meta = json.load(f)
        mt_params = {
            'mtflip' : mtw_meta["FlipAngle"],
            'sat_pulse_ms' : mtw_meta['sat_pulse_ms'],
            'interdelay_ms' : mtw_meta['interdelay_ms'],
            'ro_pulse_ms' : mtw_meta['ro_pulse_ms'],
            'tr_ms' : mtw_meta['tr_ms'],
            'ro_fa_deg' : mtw_meta['ro_fa_deg'],
            'ro_pulse_shape' : mtw_meta['ro_pulse_shape'],
            'sat_pulse_fa_deg' : mtw_meta['sat_pulse_fa_deg'],
            'sat_pulse_offset_hz' : mtw_meta['sat_pulse_offset_hz'],
            'sat_pulse_shape' : mtw_meta['sat_pulse_shape']
        }
    return mt_params

def get_qMT_json(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mtw*_echo-1_flip-*_mt-on_part-mag_MPM.json'))[0]

def get_t1flip(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}t1w*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        t1w_meta = json.load(f)
    return t1w_meta["FlipAngle"]

def get_pdflip(wildcards):
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}pdw*_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        pdw_meta = json.load(f)
    return pdw_meta["FlipAngle"]

def t1wmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}t1w*_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d.nii"
    return mag_preproc

def mt0mag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mt0*_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d.nii"
    return mag_preproc

def mtwmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}mtw*_echo-1_flip-*_mt-on_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d.nii"
    return mag_preproc

def pdwmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    csa_complete = checkpoints.add_csa_data_to_meta.get(**wildcards).output[0]
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/{wildcards.subject}/{wildcards.session}/anat/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}pdw*_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d.nii"
    return mag_preproc


rule concat_echos:
    input:
        meta_complete = check_csa_added_to_meta
    params:
        echos = get_echos
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_echos4d.nii")
    resources: 
        mem_mb=2000
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrcat {params.echos} {output}
        """


rule create_complex_images:
    input:
        mag="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-mag_echos4d.nii",
        phase="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-phase_echos4d.nii"
    output:
        mag_clipped=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-mag_echos4d_clippedtophase.nii"),
        out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-complex_echos4d.nii")
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell: #first clip mag so that it has the same number of volumes as phase, then calculate complex image
        """
        phasesize="$(mrinfo -size {input.phase} | awk '{{print $4}}')"
        magend="$((${{phasesize}}-1))"
        mrconvert {input.mag} {output.mag_clipped} -coord 3 0:${{magend}}
        mrcalc {output.mag_clipped} {input.phase} pi 4096 -div -mult -polar {output.out}
        """


rule rician_bias_corr:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-complex_echos4d.nii"
    output:
        denoised=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-complex_echos4d_riciancorr.nii"),
        noisemap=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_echos4d_riciannoisemap.nii")
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        dwidenoise {input} {output.denoised} -noise {output.noisemap}
        """


rule calculate_mag_from_complex:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-mag_echos4d_riciancorr.nii")
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrcalc {input} -abs {output}
        """

rule calculate_phase_from_complex:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-phase_echos4d_riciancorr.nii"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrcalc {input} -phase {output}
        """


rule make_n_echos_equal:
    #clip images so that they all have the same number of echos as the image with the least number of echos
    input:
        t1w_in=t1wmag_preproc,
        mt0_in=mt0mag_preproc,
        mtw_in=mtwmag_preproc,
        pdw_in=pdwmag_preproc
    output:
        t1w_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d_clipped.nii"),
        mt0_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d_clipped.nii"),
        mtw_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d_clipped.nii"),
        pdw_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d_clipped.nii")
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell: #first find smallest number of echos, then clip the other images to this number of echos
        """
        t1wsize="$(mrinfo -size {input.t1w_in} | awk '{{print $4}}')"
        mt0size="$(mrinfo -size {input.mt0_in} | awk '{{print $4}}')"
        mtwsize="$(mrinfo -size {input.mtw_in} | awk '{{print $4}}')"
        pdwsize="$(mrinfo -size {input.pdw_in} | awk '{{print $4}}')"

        sizes_array=($t1wsize $mt0size $mtwsize $pdwsize)
        min_echos=${{sizes_array[0]}}
        for i in "${{sizes_array[@]}}"; do
            (( i < min_echos )) && min_echos=$i
        done
        end_idx="$((${{min_echos}}-1))"

        mrconvert {input.t1w_in} {output.t1w_out} -coord 3 0:${{end_idx}}
        mrconvert {input.mt0_in} {output.mt0_out} -coord 3 0:${{end_idx}}
        mrconvert {input.mtw_in} {output.mtw_out} -coord 3 0:${{end_idx}}
        mrconvert {input.pdw_in} {output.pdw_out} -coord 3 0:${{end_idx}}
        """


rule concat_contrast_mag:
    input:
        t1w="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d_clipped.nii",
        mt0="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d_clipped.nii",
        mtw="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d_clipped.nii",
        pdw="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d_clipped.nii"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_echoscontrast5d.nii")
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrcat {input.t1w} {input.mt0} {input.mtw} {input.pdw} {output} -axis 4
        """


rule denoise_contrast_mag:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_echoscontrast5d.nii"
    output:
        out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_echoscontrast5d_denoise.nii"),
        noisemap="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_noisemap.nii"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 8
    conda:
        "../envs/tMPPCA.yaml"
    shell:
        """ 
        python -c 'import nibabel
from tmppca import tmppca_cpp
        
data = nibabel.load("{input}")
denoised, sigma, P, snr_gain = tmppca_cpp.denoise_tmppca(data.get_fdata(), window=[5, 5, 5])
nibabel.save(nibabel.Nifti1Image(denoised, data.affine), "{output.out}")
nibabel.save(nibabel.Nifti1Image(sigma, data.affine), "{output.noisemap}")'
        """


rule split_contrast_mag:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_echoscontrast5d_denoise.nii"
    output:
        t1w=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d_denoise.nii"),
        mt0="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d_denoise.nii",
        mtw=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d_denoise.nii"),
        pdw=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d_denoise.nii")
    resources:
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        mrconvert {input} -coord 4 0 -axes 0,1,2,3 {output.t1w}
        mrconvert {input} -coord 4 1 -axes 0,1,2,3 {output.mt0}
        mrconvert {input} -coord 4 2 -axes 0,1,2,3 {output.mtw}
        mrconvert {input} -coord 4 3 -axes 0,1,2,3 {output.pdw}
        """

# rule split_contrast_mag:
#     input:
#         contrast="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}_part-mag_echoscontrast5d_denoise.nii",
#         #same input as contrast_concat_mag
#         t1w_in=t1wmag_preproc,
#         mt0_in=mt0mag_preproc,
#         mtw_in=mtwmag_preproc,
#         pdw_in=pdwmag_preproc
#     output:
#         t1w_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_echos4d_denoise.nii"),
#         mt0_out="data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_echos4d_denoise.nii",
#         mtw_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_echos4d_denoise.nii"),
#         pdw_out=temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_echos4d_denoise.nii") 
#     resources: #limit memory by input size
#         mem_mb=lambda wc, input: 2.5 * input.size_mb
#     conda:
#         "../envs/qMT.yaml"
#     shell:
#         """
#         t1wsize="$(mrinfo -size {input.t1w_in} | awk '{{print $4}}')"
#         t1wstart=0
#         t1wend="$((${{t1wsize}}-1))"
#         mrconvert {input.contrast} {output.t1w_out} -coord 3 ${{t1wstart}}:${{t1wend}}

#         mt0size="$(mrinfo -size {input.mt0_in} | awk '{{print $4}}')"
#         mt0start=$t1wsize
#         mt0end="$((${{t1wend}}+${{mt0size}}))"
#         mrconvert {input.contrast} {output.mt0_out} -coord 3 ${{mt0start}}:${{mt0end}}

#         mtwsize="$(mrinfo -size {input.mtw_in} | awk '{{print $4}}')"
#         mtwstart="$((${{mt0end}}+1))"
#         mtwend="$((${{mt0end}}+${{mtwsize}}))"
#         mrconvert {input.contrast} {output.mtw_out} -coord 3 ${{mtwstart}}:${{mtwend}}
        
#         pdwsize="$(mrinfo -size {input.pdw_in} | awk '{{print $4}}')"
#         pdwstart="$((${{mtwend}}+1))"
#         pdwend="$((${{mtwend}}+${{pdwsize}}))"
#         mrconvert {input.contrast} {output.pdw_out} -coord 3 ${{pdwstart}}:${{pdwend}}
#         """


rule sos:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_echos4d_denoise.nii"
    output:
       "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        python3 workflow/scripts/sos_images.py {input} {output}
        """


rule synthstrip_MPM:
    input:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz"
    output:
        # temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain.nii.gz"),
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    shell:
        """
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_MPM:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule install_sct:
    output:
        ".snakemake/scripts/install_sct.done"
    resources: 
        mem_mb=2000
    shell: #Check if sct is already installed. If not, install version 7.2 for linux.
        """
        if ! command -v sct_deepseg; then
            if [[ $(uname) == Darwin* ]]; then
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_macos.sh
            else
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_linux.sh
            fi
            mv install_sct-7.2_*.sh .snakemake/scripts/
            if command -v nvidia-smi; then
                bash .snakemake/scripts/install_sct-7.2_*.sh -yicg
            else
                bash .snakemake/scripts/install_sct-7.2_*.sh -yic
            fi
            mv install_sct_log.txt .snakemake/scripts/    
        fi
        touch .snakemake/scripts/install_sct.done
        """


rule spineseg_MPM:
    input:
       "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
       ".snakemake/scripts/install_sct.done"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_seg.nii.gz"),
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz"
        # temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_discs.nii.gz"),
        # temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_totalspineseg_discs.json")
    # container:
    #     "docker://vnmd/spinalcordtoolbox_7.2:20251215"
    threads: 4
    resources: 
        mem_mb=9000
    shell:
        """
        if command -v nvidia-smi; then
            export SCT_USE_GPU=1
            export CUDA_VISIBLE_DEVICES=0
        fi
        sct_deepseg spinalcord -i {input[0]}
        cp {output[0]} {output[1]}
        """


rule brain_and_spine_mask_MPM:
    input:
       spine_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz",
       brain_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        brain_spine_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_spine_mask.nii.gz"  
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell: #combine brain and spine masks, and fill holes
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.brain_mask} -add {input.spine_mask} -fillh26 -dilD -dilD -ero -ero -bin {output.brain_spine_mask}
        """


#rules for registration with ANTS

rule DenoiseImage_mpm:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection_mpm:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """


rule register_MPM_to_t1w_ants:
    input:
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain_denoised_n4_registeredto{seq}t1w.nii.gz"),
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_denoised_n4_registeredto{contrast}{mt}{part}.nii.gz"),
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_Composite.h5",
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_InverseComposite.h5")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    shell:
        """
        antsRegistration --verbose 1 --dimensionality 3 --float 0 --write-composite-transform 1 --collapse-output-transforms 1 --output [ data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/preproc/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}_mt-{wildcards.mt}_part-{wildcards.part}_registeredto{wildcards.seq}t1w_, {output[0]}, {output[1]} ] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] --initial-moving-transform [ {input.ref}, {input.moving}, 1 ] --transform Rigid[ 0.1 ] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-6, 50 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 4x2x1x0vox --masks [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """


rule apply_reg_MPM_to_ref_ants:
    input:
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_Composite.h5"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_registeredto{seq}t1w_ants.nii.gz"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        antsApplyTransforms -d 3 -v 1 -n Linear -i {input.moving} -r {input.ref} -t {input.reg} -o {output}
        """

#rules for registration with synthmorph

rule register_MPM_to_t1w_synthmorph:
    input:
        ref = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_brain.nii.gz"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_synthmorph.lta"
    resources: 
        mem_mb=7000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell:
        """
        mri_synthmorph register -m rigid -t {output} {input.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output} {input.moving} {input.ref}
        """


rule apply_reg_MPM_to_t1w_synthmorph:
    input:
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_registeredto{seq}t1w_synthmorph.lta"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}{contrast}_mt-{mt}_part-{part}_sos_registeredto{seq}t1w_synthmorph.nii.gz"
    resources: 
        mem_mb=1000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    shell: 
        """
        mri_synthmorph apply {input.reg} {input.moving} {output}
        """

#rules for after registration


rule mtr:
    input:
        mt_off = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_sos_registeredto{seq}t1w_ants.nii.gz",
        mt_on = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_sos_registeredto{seq}t1w_ants.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_MTRmap.nii.gz"
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        """


rule setup_fit_JSPqMT_CLI:
    output:
        directory("workflow/scripts/luca_qMT/build/")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    shell:
        """
        cd workflow/scripts/luca_qMT/
        python3 setup.py build_ext --inplace
        """


rule fit_JSPqMT_CLI:
    input:
        meta_complete = check_csa_added_to_meta,
        build = "workflow/scripts/luca_qMT/build/",
        mt_off = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mt0_mt-off_part-mag_sos_registeredto{seq}t1w_ants.nii.gz",
        mt_on = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}mtw_mt-on_part-mag_sos_registeredto{seq}t1w_ants.nii.gz",
        pdw = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}pdw_mt-off_part-mag_sos_registeredto{seq}t1w_ants.nii.gz",
        t1w = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos.nii.gz",
        b1map = "data/derivatives/{field_strength}/B1map/{subject}/{session}/{subject}_{session}_acq-famp_registeredto{seq}t1w_smooth_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_spine_mask.nii.gz"
    params:
        mt_params = get_qMT_params,
        t1flip = get_t1flip,
        pdflip = get_pdflip
    output:
        mpfmap = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_MPFmap.nii.gz",
        t1map = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        r1map = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_R1map.nii.gz"
    threads: 4
    resources:
        mem_mb=4000
    conda:
        "../envs/qMT.yaml"
    # container:
    #     "docker://hugodary/vibe_mt:latest"
    shell:
        """
        python3 workflow/scripts/luca_qMT/fit_JSPqMT_CLI.py \
        {input.mt_off},{input.mt_on} \
        {input.pdw},{input.t1w} \
        {output.mpfmap} \
        {output.t1map} \
        --R1f {output.r1map} \
        --MTw_TIMINGS {params.mt_params[sat_pulse_ms]},{params.mt_params[interdelay_ms]},{params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_TIMINGS {params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_PARX {params.pdflip},{params.t1flip},{params.mt_params[ro_pulse_shape]} \
        --MTw_PARX {params.mt_params[ro_fa_deg]},{params.mt_params[ro_pulse_shape]},{params.mt_params[sat_pulse_fa_deg]},{params.mt_params[sat_pulse_offset_hz]},{params.mt_params[sat_pulse_shape]} \
        --B1 {input.b1map} \
        --mask {input.mask} \
        --nworkers {threads} \
        --cpp_opt --use_GBM
        """

#rules for registering to MP2RAGE with ANTS

rule apply_brainmask_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        DenoiseImage -i {input.input_image} -x {input.mask_image} -d 3 -n Rician -s 1 -p 1 -r 2 -v 1 -o {output}
        """


rule N4BiasFieldCorrection_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    shell:
        """
        N4BiasFieldCorrection -i {input.input_image} -x {input.mask_image} -d 3 -s 4 -c [ 50x50x50x50, 0 ] -v 1 -o {output}
        """


rule register_MPM_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/uncorr_qT1_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/MPM/{subject}/{session}/preproc/{subject}_{session}_acq-{seq}t1w_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain_denoised_n4_registeredtoMP2RAGE{mp2rage_params}.nii.gz"),
        temp("data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit_brain_denoised_n4_registeredto{seq}T1map.nii.gz"),
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5",
        temp("data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE{mp2rage_params}_InverseComposite.h5")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    shell:
        """
        antsRegistration --verbose 1 --dimensionality 3 --float 0 --write-composite-transform 1 --collapse-output-transforms 1 --output [ data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_registeredtoMP2RAGE{wildcards.mp2rage_params}_, {output[0]}, {output[1]} ] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] --initial-moving-transform [ {input.ref}, {input.moving}, 1 ] --transform Affine[ 0.1 ] --metric MI[ {input.ref}, {input.moving}, 1, 32 ] --convergence [ 1000x500x250x100, 1e-6, 50 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 4x2x1x0vox --masks [ {input.ref_mask}, {input.moving_mask} ] --random-seed 1
        """


rule apply_reg_MPM_to_MP2RAGE_ants:
    input:
        # moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
        ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE{mp2rage_params}_Composite.h5"
    output:
        "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE{mp2rage_params}_ants.done"
    resources: 
        mem_mb=500
    conda:
        "../envs/qMT.yaml"
    shell:
        """
        MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        mkdir -p data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE{wildcards.mp2rage_params}_ants
        for map in "${{MPMmaps[@]}}"; do
            moving="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
            out="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE{wildcards.mp2rage_params}_ants/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map"_registeredtoMP2RAGE{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms -d 3 -v 1 -n Linear -i $moving -r {input.ref} -t {input.reg} -o $out
            fi
        done
        touch {output}
        """


# #rules for registration with easyreg

# rule register_MPM_to_MP2RAGE_easyreg:
#     input:
#         moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
#         # moving_seg = "data/derivatives/{ield_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_seg.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz",
#         ref_seg = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/MP2RAGE_synthseg.nii.gz"
#     params:
#         moving_seg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_seg.nii.gz"
#     output:
#         # moving_reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_registeredtoMP2RAGE_easyreg.nii.gz",
#         fwd_field = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGEmatrix.nii.gz",
#         bak_field = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGEmatrix_inverse.nii.gz"
#     resources:
#         mem_mb=15000
#     threads: 8
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_easyreg --ref {input.ref} --flo {input.moving} --ref_seg {input.ref_seg} --flo_seg {params.moving_seg} --fwd_field {output.fwd_field} --bak_field {output.bak_field} --threads {threads} --affine_only
#         """


# rule apply_reg_MPM_to_MP2RAGE_easyreg:
#     input:
#         "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGEmatrix.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE_easyreg.done"
#     threads: 8
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_easyreg
#         for map in "${{MTmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_easyreg/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_easywarp --i $moving --o $out --field {input} --threads {threads}
#             fi
#         done
#         touch {output}
#         """


# #rules for registration with synthmorph

# rule register_MPM_to_MP2RAGE_synthmorph:
#     input:
#         moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map_brain.nii.gz",
#         ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit_brain.nii.gz"
#     output:
#         reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE.lta",
#         reg_inv = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE_inverse.lta"
#     resources: 
#         mem_mb=7000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell:
#         """
#         mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref} -g || mri_synthmorph register -m rigid -t {output.reg} {input.moving} {input.ref}
#         lta_convert --inlta {output.reg} --outlta {output.reg_inv} --invert
#         """


# rule apply_reg_MPM_to_MP2RAGE_synthmorph:
#     input:
#         # moving = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_T1map.nii.gz",
#         # ref = "data/derivatives/{field_strength}/MP2RAGE/{subject}/{session}/qT1_msUnit.nii.gz",
#         reg = "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_registeredtoMP2RAGE.lta"
#     output:
#         "data/derivatives/{field_strength}/MPM/{subject}/{session}/{subject}_{session}_acq-{seq}_apply_reg_MPM_to_MP2RAGE_synthmorph.done"
#     resources: 
#         mem_mb=1000
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     shell: #register and reslice to MP2RAGE
#         """
#         MPMmaps=("MPFmap" "MTRmap" "R1map" "T1map")
#         mkdir -p data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_synthmorph
#         for map in "${{MPMmaps[@]}}"; do
#             moving="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map".nii.gz"
#             out="data/derivatives/{wildcards.field_strength}/MPM/{wildcards.subject}/{wildcards.session}/registered_to_MP2RAGE_synthmorph/{wildcards.subject}_{wildcards.session}_acq-{wildcards.seq}_"$map"_registeredtoMP2RAGE.nii.gz"
#             if [ -f $moving ]; then
#                 mri_synthmorph apply {input.reg} $moving $out
#             fi
#         done
#         touch {output}
        
#         """  
