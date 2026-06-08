#/bin/bash

function parse_yaml { #function from https://stackoverflow.com/a/21189044
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

parse_yaml config/snakemake_config.yaml

usage() { #function to display script help
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "-h, --help        Display this help message and exit"
    echo "-i, --input       Path to the folder containing the input DICOMS"
    echo "-p, --xml         Path to the folder containing the scanning protocol xml files"
    echo "-d, --dag         Produce DAG of pipeline instead of running the pipeline"
    echo "-n, --dry-run     Display what would be done without executing the pipeline"
}

handle_options() { #function for handling options when this script is called
    while [ $# -gt 0]; do #while number of arguments to the script is greater than 0
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
}

snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --dag | sed -n "/digraph/,/}/p" | dot -Tsvg > pipeline_dag.svg

#generate BIDS folder first
snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --sdm conda --cores 2 data/rawdata/bids/3T/code/bidscoin/fixmeta.log

#then run image processing
if command -v nvidia-smi; then
    #include nvidia arguments for singularity if GPU is available
    snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --resources mem_mb=63000 --sdm conda apptainer --cores 20 --singularity-args "--nv -e" --rerun-incomplete
else
    snakemake --config input_dicoms_path="/home/rflaherty/test_dicoms" protocol_path="/home/rflaherty/NORMA_DEV_CPP/" --resources mem_mb=9300 --sdm conda apptainer --cores 7 --rerun-incomplete
fi
