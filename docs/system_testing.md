# System testing

The system testing implemented for this pipeline tests whether the pipeline runs from start to finish without any error.
This testing uses test datasets present in [`.test/ngs-data/test_project`](../.test/ngs-data/test_project), which
reflects a test project containing four samples -- Two samples without priorQC data (`no_priorQC`) and two with priorQC
data (`include_priorQC`). [See .test/README.md](../.test/README.md) for more info on how these test datasets were
created.

!!! warning

    This testing does not verify that pipeline's output are correct. Instead, its purpose is to ensure that
    pipeline runs from beginning to end without any execution error for the given test dataset.


## Set up dataset dependencies

Certain tools used in QuaC require certain datasets to be present. A script is made available here to retrieve them and then process them as needed.

To run the script:

```sh
cd .test
./setup_dependency_datasets.sh
```

Downloaded datasets here can then be readily supplied to QuaC by supplying `--workflow_config .test/configs/test_workflow.yaml`.

## How to run

!!! info

    Choose the value of variable `USE_SLURM` below depending on if you would like to use slurm or 
    not to run jobs.

```sh
# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac


## use slurm or not
# use this to submit jobs to slurm for the parent snakemake process 
# as well as for the snakemake triggered jobs
USE_SLURM="--snakemake_slurm --subtasks_slurm"
# USE_SLURM=""  # uncomment this, comment out the above line, and use this if you don't want to use slurm at all


########## No prior QC data involved ##########
PROJECT_CONFIG="project_2samples"
PRIOR_QC_STATUS="no_priorQC"

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/wgs_quac_watch_config.yaml" \
      --workflow_config ".test/configs/test_workflow.yaml" \
      $USE_SLURM

# Exome mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_exome-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --workflow_config ".test/configs/test_workflow.yaml" \
      --exome \
      $USE_SLURM


########## Includes prior QC data and allows sample renaming ##########
PROJECT_CONFIG="project_2samples"
PRIOR_QC_STATUS="include_priorQC"

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/wgs_quac_watch_config.yaml" \
      --include_prior_qc \
      --allow_sample_renaming \
      --workflow_config ".test/configs/test_workflow.yaml" \
      $USE_SLURM

# Exome mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_exome-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome \
      --include_prior_qc \
      --allow_sample_renaming \
      --workflow_config ".test/configs/test_workflow.yaml" \
      $USE_SLURM
```

!!! note

    Use `PROJECT="project_1sample"` to test out a project with only one sample.

## Expected output files

Output directory structure for WGS + `include_prior_qc` mode would look like this.

```sh
$ tree -d $USER_SCRATCH/tmp/quac/results/test_project_2samples_wgs-no_priorQC/ -L 5
$USER_SCRATCH/tmp/quac/results/test_project_2samples_wgs-no_priorQC/
└── analysis
    ├── C
    │   └── qc
    │       ├── bcftools-index
    │       │   └── ...
    │       ├── bcftools-stats
    │       │   └── ...
    │       ├── mosdepth
    │       │   └── ...
    │       ├── multiqc_final_pass
    │       │   ├── ...
    │       │   └── C_multiqc.html
    │       ├── multiqc_initial_pass
    │       │   ├── ...
    │       │   └── C_multiqc.html
    │       ├── picard-stats
    │       │   └── ...
    │       ├── quac_watch
    │       │   └── ...
    │       ├── qualimap
    │       │   └── ...
    │       ├── samtools-stats
    │       │   └── ...
    │       └── verifyBamID
    │           └── ...
    ├── D
    │   └── qc
    │       └── same directory structure as that of sample C
    └── project_level_qc
        ├── covviz
        │   └── ...
        ├── indexcov
        │   └── ...
        ├── mosdepth
        │   └── ...
        ├── multiqc
        │   ├── ...
        │   └── multiqc_report.html
        └── somalier
            ├── ancestry
            │   └── ...
            ├── extract
            │   └── ...
            └── relatedness
                └── ...
```

!!! note

    Certain tools (eg. indexcov and covviz) are not executed when QuaC is run in exome mode (`--exome`).
