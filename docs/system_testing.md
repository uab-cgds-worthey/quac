# System testing

The system testing implemented for this pipeline tests whether the pipeline runs from start to finish without any error.
This testing uses test datasets present in `.test/ngs-data/test_project`, which reflects a test project containing four
samples -- Two samples without priorQC data (`no_priorQC`) and two with priorQC data (`include_priorQC`). See
`.test/README.md` for more info on how these test datasets were created.

!!! warning

    This testing does not verify that pipeline's output are correct. Instead, its purpose is to ensure that
    pipeline runs from beginning to end without any execution error for the given test dataset.


## How to run

!!! info

    Choose the value of variable `USE_SLURM` below depending on if you would like to use slurm or 
    not to run jobs.

```sh
# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2023.07-2

# activate conda env
conda activate quac

## use slurm or not
# use this to submit jobs to slurm for the parent snakemake process 
# as well as for the snakemake triggered jobs
USE_SLURM="--cli_cluster_config configs/cli_cluster_config.json 
           --snakemake_cluster_config configs/snakemake_cluster_config.json"
# USE_SLURM=""  # uncomment this, comment out the above line, and use this if you don't want to use slurm at all. Useful for development purposes


run_quac() {
      PROJECT_CONFIG=$1
      SEQ_TYPE=$2
      PRIOR_QC_STATUS=$3
      USE_SLURM=$4
      
      python src/run_quac.py \
            --sample_config ".test/configs/sample_config/${PROJECT_CONFIG}_${SEQ_TYPE}${PRIOR_QC_STATUS}.tsv" \
            --pedigree ".test/configs/pedigree/${PROJECT_CONFIG}${PRIOR_QC_STATUS}.ped" \
            --outdir "data/quac/results/test_${PROJECT_CONFIG}_${SEQ_TYPE}${PRIOR_QC_STATUS}/analysis" \
            --quac_watch_config "configs/quac_watch/${SEQ_TYPE}_quac_watch_config.yaml" \
            --workflow_config "configs/workflow.yaml" \
            $PRIOR_QC_STATUS \
            $USE_SLURM 
}

########## No prior QC data involved ##########
# WGS mode
PROJECT_CONFIG="project_2samples"
SEQ_TYPE="wgs"
PRIOR_QC_STATUS=""

run_quac "$PROJECT_CONFIG" "$SEQ_TYPE" "$PRIOR_QC_STATUS" "$USE_SLURM"

# Exome mode
PROJECT_CONFIG="project_2samples"
SEQ_TYPE="exome"
PRIOR_QC_STATUS=""

run_quac "$PROJECT_CONFIG" "$SEQ_TYPE" "$PRIOR_QC_STATUS" "$USE_SLURM"


########## Includes prior QC data and allows sample renaming ##########
# WGS mode
PROJECT_CONFIG="project_2samples"
SEQ_TYPE="wgs"
PRIOR_QC_STATUS="--include_prior_qc"

run_quac "$PROJECT_CONFIG" "$SEQ_TYPE" "$PRIOR_QC_STATUS" "$USE_SLURM"

# Exome mode
PROJECT_CONFIG="project_2samples"
SEQ_TYPE="exome"
PRIOR_QC_STATUS="--include_prior_qc"

run_quac "$PROJECT_CONFIG" "$SEQ_TYPE" "$PRIOR_QC_STATUS" "$USE_SLURM"
```

## Expected output files

Output directory structure for WGS + `include_prior_qc` mode would look like this.

```sh
$ tree data/quac/results/test_project_2samples_wgs-include_priorQC/ -L 5
data/quac/results/test_project_2samples_wgs-include_priorQC/
└── analysis
    ├── A
    │   └── qc
    │       ├── bcftools-index
    │       │   └── ...
    │       ├── bcftools-stats
    │       │   └── ...
    │       ├── fastqc-raw
    │       │   └── ...
    │       ├── fastq_screen-raw
    │       │   └── ...
    │       ├── mosdepth
    │       │   └── ...
    │       ├── multiqc_final_pass
    │       │   ├── ...
    │       │   └── A_multiqc.html        <--- Sample-level multiqc output file
    │       ├── multiqc_initial_pass
    │       │   ├── ...
    │       │   └── A_multiqc.html
    │       ├── picard-stats
    │       │   └── ...
    │       ├── quac_watch
    │       │   └── ...
    │       ├── qualimap
    │       │   └── ...
    │       ├── samtools-stats
    │       │   └── ...
    │       └── verifyBamID
    │           └── ...
    ├── B
    │   └── qc
    │       └── same directory structure as that of sample A
    └── project_level_qc
        ├── covviz
        │   └── ...
        ├── indexcov
        │   └── ...
        ├── mosdepth
        │   └── ...
        ├── multiqc
        │   ├── configs
        │   │   └── aggregated_rename_configs.tsv
        │   ├── multiqc_report_data
        │   │   └── ...
        │   └── multiqc_report.html        <--- Project-level multiqc output file
        └── somalier
            ├── ancestry
            │   └── ...
            ├── extract
            │   └── ...
            └── relatedness
                └── ...
```

!!! note

    Certain tools (eg. indexcov and covviz) are not executed when QuaC is run in exome mode (`--exome`).
