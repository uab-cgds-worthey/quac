#!/usr/bin/env bash
#SBATCH --job-name=quac
#SBATCH --output=logs/quac-%j.log
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8G
#SBATCH --partition=short

set -euo pipefail

module reset
module load Anaconda3/2020.02
module load snakemake/5.9.1-foss-2018b-Python-3.6.6

# PROJECT_NAME="UDN_Phase1_EAWorthey"
PROJECT_NAME=$1
PEDIGREE_FPATH="data/raw/ped/${PROJECT_NAME}.ped"
OUT_DIR="data/processed/${PROJECT_NAME}"

MODULES="all"
# MODULES="mosdepth"
# EXTRA_ARGS="-n"
EXTRA_ARGS=""

snakemake \
    --snakefile "workflow/Snakefile" \
    --config modules="${MODULES}" project_name="${PROJECT_NAME}" ped="${PEDIGREE_FPATH}" out_dir="${OUT_DIR}" \
    --use-conda \
    --profile 'configs/snakemake_slurm_profile/{{cookiecutter.profile_name}}' \
    --cluster-config 'configs/cluster_config.json' \
    --cluster 'sbatch --ntasks {cluster.ntasks} --partition {cluster.partition} --cpus-per-task {cluster.cpus-per-task} --mem {cluster.mem} --output {cluster.output} --parsable' \
    $EXTRA_ARGS
