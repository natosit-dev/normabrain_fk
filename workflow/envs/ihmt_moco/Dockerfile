FROM continuumio/anaconda3:latest

RUN apt-get update && apt-get install -y dc bc

WORKDIR /app

COPY environment.yml /app/environment.yml
RUN conda env create -n ihMT_MoCo -f environment.yml \
    && rm -rf /opt/conda/pkgs/*

COPY . /app/

ENV PATH="/opt/conda/envs/ihMT_MoCo/bin:$PATH"

ENTRYPOINT [ "sh", "-c", "/bin/bash" ]