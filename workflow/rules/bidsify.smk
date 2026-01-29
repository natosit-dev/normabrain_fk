checkpoint copy_dicoms_by_field_strength:
    input:
        expand("{input_dicoms_path}", input_dicoms_path=config["input_dicoms_path"])
    output:
        dir = directory("data/rawdata/dicoms")
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/copy_dicoms_by_field_strength.log"
    shell:
        """
        python3 workflow/scripts/copy_dicoms_by_field_strength.py {input} {output.dir}
        """

# def get_dicoms_folders(wildcards):
#     checkpoint_output = checkpoints.copy_dicoms_by_field_strength.get(**wildcards).output[0]
#     return expand("data/{field_strength}/rawdata/dicoms/",
#             field_strength=glob_wildcards(os.path.join(checkpoint_output, "{f}/rawdata/dicoms/")).f)

def get_dicoms_folders(wildcards):
    checkpoint_output = checkpoints.copy_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand(os.path.join(checkpoint_output, "{field_strength}"),
        field_strength=wildcards.field_strength)

rule bidsmapper:
    input:
        get_dicoms_folders
        # os.path.join(rules.copy_dicoms_by_field_strength.output.dir, "{field_strength}/rawdata/dicoms/"),
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/bidsmap.yaml"
        # directory("data/{field_strength}/rawdata/bids")
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/bidsmapper_{field_strength}.log"
    shell:
        """
        bidsmapper {input} data/rawdata/bids/{wildcards.field_strength} -t config/bidsmap_normabrain_template -a
        touch {output}
        """

rule bidscoiner:
    input:
        # "data/{field_strength}/rawdata/bids/code/bidscoin/bidsmap.yaml",
        # dicoms = "data/{field_strength}/rawdata/dicoms/"
        rules.bidsmapper.output,
        dicoms = get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/participants.tsv"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/bidscoiner_{field_strength}.log"
    shell:
        """
        bidscoiner {input.dicoms} data/rawdata/bids/{wildcards.field_strength}
        touch {output}
        """

rule add_csa_data_to_meta:
    input:
        rules.bidscoiner.output
    output:
        "results/add_csa_data_to_meta_{field_strength}.complete"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/add_csa_data_to_meta_{field_strength}.log"
    shell:
        """
        python3 workflow/scripts/add_csa_data_to_meta.py data/rawdata/bids/{wildcards.field_strength}
        touch {output}
        """