#/bin/bash

#default variable values
subject_list_dicom="*"
qMT_sequence="vibeMT"
qMT_contrasts='["mt0", "mtw", "pdw", "t1w"]'
run_all=false
run_bids=false
run_mp2rage=false
run_ihmt=false
run_qmt=false
run_dwi=false
run_qsm=false
run_reg_seg=false
use_gpu=false
run_dag=false
do_dry_run=false

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

#config may override default variable values defined above
parse_yaml config/snakemake_config.yaml

usage() { #function to display script help
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "-h, --help        Display this help message and exit."
    echo "REQUIRED flags ===="
    echo "-i, --input   Path to the folder containing the input DICOMS. No default."
    echo "--xml         Path to the folder containing the scanning protocol xml files. No default. Necessary for setting the MP2RAGE and ihMT echo spacing. If no xml files are found in the provided folder, sensible defaults for echo spacing are set."
    echo "--subjects    Space-separated list of subject DICOM folder names to include in the analysis. The default is all subjects in the input folder."
    echo "--qmt_seq     The base name of the qMT sequence used in the ProtocolName. The default is vibeMT"
    echo "--qmt_con     The bracketed comma-separated list of contrasts collected for the qMT sequence as described in the ProtocolName. The default is ["mt0", "mtw", "pdw", "t1w"]"
    echo "--mem_mb      Memory available for the pipeline, in MB. The default is min(max(2*input_size_mb, 1000), 8000) i.e. twice the input DICOMS folder size but no less than 1 GB and no more than 8 GB."
    echo "-c, --cores   CPU cores used for the pipeline. The default is all available CPU cores."
    echo "REQUIRED: Choose at least one of the below flags ===="
    echo "--all         Run all modules of the pipeline."
    echo "--bids        Run the bids module."
    echo "--mp2rage     Run the MP2RAGE module."
    echo "--ihmt        Run the ihMT module."
    echo "--qmt         Run the qMT module."
    echo "--dwi         Run the DWI module."
    echo "--qsm         Run the QSM module."
    echo "--reg_seg     Run the multimodal registration to MP2RAGE and segmentation module."
    echo "OPTIONAL flags ===="
    echo "-g, --gpu         Use GPU." 
    echo "-d, --dag         Produce DAG of pipeline instead of running the pipeline."
    echo "-n, --dry_run     Display what would be done without executing the pipeline."        
}

has_argument() { #function from https://medium.com/@wujido20/handling-flags-in-bash-scripts-4b06b4d0ed04
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() { #function from https://medium.com/@wujido20/handling-flags-in-bash-scripts-4b06b4d0ed04
  echo "${2:-${1#*=}}"
}

handle_options() { #function for handling options when this script is called
    while [ $# -gt 0]; do #while number of arguments to the script is greater than 0
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
            -i | --input*)
                if ! has_argument $@; then
                    echo "Input DICOMS folder not specified." >&2
                    usage
                    exit 1
                fi

                input_dicoms_path=$(extract_argument $@)

                shift
                ;;
            --xml*)
                if ! has_argument $@; then
                    echo "XML protocol folder not specified." >&2
                    usage
                    exit 1
                fi

                protocol_path=$(extract_argument $@)

                shift
                ;;
            --subjects*)
                if ! has_argument $@; then
                    subjects="*"
                fi

                subjects=$(extract_argument $@)

                shift
                ;;
            --qmt_seq*)
                if ! has_argument $@; then
                    qmt_sequence="vibeMT"
                fi

                qmt_sequence=$(extract_argument $@)

                shift
                ;;
            --qmt_con*)
                if ! has_argument $@; then
                    qmt_contrasts='["mt0", "mtw", "pdw", "t1w"]'
                fi

                qmt_contrasts=$(extract_argument $@)

                shift
                ;;
            --mem_mb*)
                if ! has_argument $@; then
                    memory=0
                fi

                memory=$(extract_argument $@)

                shift
                ;;
            -c | --cores*)
                if ! has_argument $@; then
                    cores=0
                fi

                cores=$(extract_argument $@)

                shift
                ;;
            --all)
                run_all=true
                ;;
            --bids)
                run_bids=true
                ;;
            --mp2rage)
                run_mp2rage=true
                ;;
            --ihmt)
                run_ihmt=true
                ;;
            --qmt)
                run_qmt=true
                ;;
            --dwi)
                run_dwi=true
                ;;
            --qsm)
                run_qsm=true
                ;;
            --reg_seg)
                run_reg_seg=true
                ;;
            -g | --gpu)
                use_gpu=true
                ;;
            -d | --dag)
                run_dag=true
                ;;
            -n | --dry_run)
                do_dry_run=true
                ;;
            *)
                echo "Invalid option: $1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

handle_options "$@"

gpu_string=""
dag_string1=""
dag_string2=""
dry_run_string=""
config_string="--config input_dicoms_path=${input_dicoms} protocol_path=${protocol_path} subject_list_dicom=${subject_list_dicom} qMT_sequence=${qMT_sequence} qMT_contrasts=${qMT_contrasts}"
mem_string="--resources mem_mb=${memory}"
cores_string="--cores ${cores}"
rerun_incomplete_string="--rerun-incomplete"

if [ "$memory"=0 ]; then
    mem_string=""
fi

if [ "$cores"=0 ]; then
    cores_string=""
fi

if [ "$run_all"=true ]; then
    target_string=""
fi

if [ "$run_reg_seg"=true ]; then
    target_string=""
fi

if [ "$run_bids"=true ]; then
    resources_string=""
    sdm_string="--sdm conda"
    cores_string="--cores 1"
    target_string=" gather_add_csa_data_to_meta"
fi

if [ "$run_mp2rage"=true ]; then
    target_string+=" aggregate_mp2rage"
fi

if [ "$run_ihmt"=true ]; then
    target_string+=" aggregate_ihmt_maps"
fi

if [ "$run_ihmt"=true ] && [ "$run_reg_seg"=true ]; then
    target_string+=" aggregate_multimodal_ihmt_mp2rage"
fi

if [ "$run_qmt"=true ]; then
    target_string+=" aggregate_qMT"
fi

if [ "$run_qmt"=true ] && [ "$run_reg_seg"=true ]; then
    target_string+=" aggregate_multimodal_qMT_mp2rage"
fi

if [ "$run_dwi"=true ]; then
    target_string+=" aggregate_dki"
fi

if [ "$run_dwi"=true ] && [ "$run_reg_seg"=true ]; then
    target_string+=" aggregate_multimodal_dwi_mp2rage"
fi

if [ "$run_qsm"=true ]; then
    target_string+=" aggregate_qsmxt"
fi

if [ "$use_gpu"=true ]; then
    gpu_string="--singularity-args '--nv -e'"
fi

#change most strings to blank if running dag
if [ "$run_dag"=true ]; then
    resources_string=""
    sdm_string=""
    cores_string=""
    sing_string=""
    rerun_incomplete_string=""
    dag_string1="--dag dot " 
    dag_string2=" | sed -n '/digraph/,/}/p' | dot -Tsvg > pipeline_dag.svg"
fi

if [ "$do_dry_run"=true]; then
    dry_run_string="--dry-run"
fi


snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --dag dot | sed -n "/digraph/,/}/p" | dot -Tsvg > pipeline_dag.svg

#generate BIDS folder first
snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --sdm conda --cores 1 data/rawdata/bids/3T/code/bidscoin/fixmeta.log

#then run image processing
if command -v nvidia-smi; then
    #include nvidia arguments for singularity if GPU is available
    snakemake --config input_dicoms_path="/DATA_CEMEREM/data/users/ttroalen/vida/normadev/" protocol_path="/DATA_CNS/PROJECTS/NORMABRAIN/NORMA_DEV_CPP/" --resources mem_mb=63000 --sdm conda apptainer --cores 20 --singularity-args "--nv -e" --rerun-incomplete
else
    snakemake --config input_dicoms_path="/home/rflaherty/test_dicoms" protocol_path="/home/rflaherty/NORMA_DEV_CPP/" --resources mem_mb=9300 --sdm conda apptainer --cores 7 --rerun-incomplete
fi
