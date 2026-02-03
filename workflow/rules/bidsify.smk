checkpoint copy_dicoms_by_field_strength:
    input:
        expand("{input_dicoms_path}", input_dicoms_path=config["input_dicoms_path"])
    output:
        dir = directory("data/rawdata/dicoms")
    conda:
        "../envs/bidscoin.yaml"
    shell:
        """
        python3 workflow/scripts/copy_dicoms_by_field_strength.py {input} {output.dir}
        """

def get_dicoms_folders(wildcards):
    checkpoint_output = checkpoints.copy_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand(os.path.join(checkpoint_output, "{field_strength}"),
        field_strength=wildcards.field_strength)

rule bidsmapper:
    input:
        get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/bidsmap.yaml"
    conda:
        "../envs/bidscoin.yaml"
    shell:
        """
        bidsmapper {input} data/rawdata/bids/{wildcards.field_strength} -t config/bidsmap_normabrain_template -a
        touch {output}
        """

rule bidscoiner:
    input:
        rules.bidsmapper.output,
        dicoms = get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/participants.tsv"
    conda:
        "../envs/bidscoin.yaml"
    shell:
        """
        bidscoiner {input.dicoms} data/rawdata/bids/{wildcards.field_strength}
        touch {output}
        """

rule add_csa_data_to_meta:
    input:
        rules.bidscoiner.output
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/fixmeta.log"
    conda:
        "../envs/bidscoin.yaml"
    shell:
        """
        python3 workflow/scripts/add_csa_data_to_meta.py data/rawdata/bids/{wildcards.field_strength}
        """