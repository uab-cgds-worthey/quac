# System testing

The system testing implemented for this pipeline tests whether the pipeline runs from start to finish without any error.
This testing uses test datasets present in [`.test/ngs-data/test_project`](../.test/ngs-data/test_project), which reflects
a test project containing four samples (2 with input needed when `include_priorQC` is used and 2 other samples without
priorQC data). [See here](../.test/README.md) for more info on how these test datasets were created.

!!! warning

    This testing does not verify that pipeline's output are correct. Instead, its purpose is to ensure that
    pipeline runs from beginning to end without any execution error for the given test dataset.


## How to run

```sh
# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

########## No prior QC data involved ##########
PROJECT_CONFIG="project_2samples"
PRIOR_QC_STATUS="no_priorQC"

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" 

# Exome mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_exome-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome


########## Includes prior QC data and allows sample renaming ##########
PROJECT_CONFIG="project_2samples"
PRIOR_QC_STATUS="include_priorQC"

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" \
      --include_prior_qc \
      --allow_sample_renaming

# Exome mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_exome-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --include_prior_qc \
      --allow_sample_renaming \
      --exome
```

!!! note

    Use `PROJECT="project_1sample"` to test out a project with only one sample.

## Expected output files

```sh
$ tree $USER_SCRATCH/tmp/quac/results/test_project_2_samples/ -d -L 4
/data/scratch/manag/tmp/quac/results/test_project_2_samples/
└── analysis
    ├── A
    │   └── qc
    │       ├── bcftools-index
    │       │   └── ...
    │       ├── bcftools-stats
    │       │   └── ...
    │       ├── mosdepth
    │       │   └── ...
    │       ├── multiqc_final_pass
    │       │   ├── ...
    │       │   └── A_multiqc.html
    │       ├── multiqc_initial_pass
    │       │   ├── ...
    │       │   └── A_multiqc.html
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
    ├── B
    │   └── qc
    │       └── same directory structure as that of sample A
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


