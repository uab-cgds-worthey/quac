#!/usr/bin/env bash
#SBATCH --job-name=quac
#SBATCH --output=logs/quac-%j.log
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=8G
#SBATCH --partition=short

set -euo pipefail

module reset
module load Anaconda3/2020.02
module load snakemake/5.9.1-foss-2018b-Python-3.6.6

snakemake -s workflow/Snakefile --use-conda -p
