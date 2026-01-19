rule copy_dicoms_by_field_strength:
    input:
        expand("{input_dicoms_path}", input_dicoms_path=config["input_dicoms_path"])
    output:
        directory("data/")
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/copy_dicoms_by_field_strength.log"
    shell:
        """
        python3 workflow/scripts/copy_dicoms_by_field_strength.py {input} {output}
        """

rule bidsmapper:
    input:
        dicoms = expand("data/{field_strength}/rawdata/dicoms/", field_strength=FIELD_STRENGTHS),
        new_config = "config/snakemake_config.yaml"
    output:
        "data/{field_strength}/rawdata/bids/code/bidscoin/bidsmap.yaml"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/bidsmapper_{field_strength}.log"
    shell:
        """
        bidsmapper {input.dicoms} data/{wildcards.field_strength}/rawdata/bids/ -t config/bidsmap_normabrain_template -n '*' -m '*' -a
        """

rule bidscoiner:
    input:
        "data/{field_strength}/rawdata/bids/code/bidscoin/bidsmap.yaml",
        dicoms = expand("data/{field_strength}/rawdata/dicoms/", field_strength=FIELD_STRENGTHS)
    output:
        "data/{field_strength}/rawdata/bids/participants.tsv"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/bidscoiner_{field_strength}.log"
    shell:
        """
        bidscoiner {input.dicoms} data/{wildcards.field_strength}/rawdata/bids/
        """

rule add_csa_data_to_meta:
    input:
        expand("data/{field_strength}/rawdata/bids/participants.tsv", field_strength=FIELD_STRENGTHS)
    output:
        "results/add_csa_data_to_meta_{field_strength}.complete"
    conda:
        "../envs/bidscoin.yaml"
    log:
        "results/logs/add_csa_data_to_meta_{field_strength}.log"
    shell:
        """
        python3 workflow/scripts/add_csa_data_to_meta.py data/{wildcards.field_strength}/rawdata/bids/
        touch {output}
        """