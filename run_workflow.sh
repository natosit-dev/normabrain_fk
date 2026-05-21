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
