#for creating data/rawdata folder structure necessary for the rest of the pipeline

def get_dicoms_folders(wildcards):
    checkpoint_output = checkpoints.copy_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand(os.path.join(checkpoint_output, "{field_strength}"),
        field_strength=wildcards.field_strength)

def check_bidscoiner_ran(wildcards):
    checkpoint_output = checkpoints.bidscoiner.get(**wildcards).output[0]
    return checkpoint_output


checkpoint copy_dicoms_by_field_strength:
    input:
        expand("{input_dicoms_path}", input_dicoms_path=config["input_dicoms_path"])
    params:
        subject_list=config["subject_list_dicom"]
    output:
        directory("data/rawdata/dicoms")
    conda:
        "../envs/bidscoin.yaml"
    log:
        "logs/copy_dicoms_by_field_strength.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python3 workflow/scripts/copy_dicoms_by_field_strength.py {input} {output} {params.subject_list}
        """


rule bidsmapper:
    input:
        get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/bidsmap.yaml"
    params:
        outdir="data/rawdata/bids/{field_strength}",
        template="config/bidsmap_normabrain_template",
        outcode="data/rawdata/bids/{field_strength}/code/bidscoin/bidsmapper.log"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "logs/{field_strength}/bidsmapper.log"
    shell:
        """
        bidsmapper {input} {params.outdir} -t {params.template} -a
        touch {output}
        cp {params.outcode} {log}
        """


checkpoint bidscoiner:
    input:
        rules.bidsmapper.output,
        dicoms = get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/participants.tsv"
    params:
        outdir="data/rawdata/bids/{field_strength}",
        outcode="data/rawdata/bids/{field_strength}/code/bidscoin/bidscoiner.log"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "logs/{field_strength}/bidscoiner.log"
    shell:
        """
        bidscoiner {input.dicoms} {params.outdir}
        touch {output}
        cp {params.outcode} {log}
        """


checkpoint add_csa_data_to_meta:
    input:
        bidscoiner = check_bidscoiner_ran
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/fixmeta.log"
    params:
        outdir="data/rawdata/bids/{field_strength}"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "logs/{field_strength}/add_csa_data_to_meta.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python3 workflow/scripts/add_csa_data_to_meta.py {params.outdir}
        """