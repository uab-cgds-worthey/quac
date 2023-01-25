# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

## What is QuaC?

QuaC is a snakemake-based **pipeline** that runs several QC tools for WGS/WES samples and then summarizes their results
using pre-defined, configurable QC thresholds. 

In summary, QuaC performs the following:

- Runs several QC tools using `BAM` and `VCF` files as input. At our center CGDS, these files are produced as part of
  the [small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
- Using *QuaC-Watch* tool, it performs QC checkup based on the expected thresholds for certain QC metrics and summarizes
  the results for easier human consumption
- Aggregates QC output produced here as well as those by the small variant caller pipeline using mulitqc, both at the
  sample level and project level.
- Optionally, above mentioned QC checkup and QC aggregation steps can accept pre-run results from few QC tools (fastqc,
   fastq-screen, picard's markduplicates). At CGDS, these files are produced as part of the [small variant caller
   pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).


## How to run QuaC

### Input requirements

- Pedigree file supplied via `--pedigree`. Only the samples that are supplied in pedigree file will be processed by QuaC
  and all of these samples must belong to the same project.
  - *For CGDS use only*: This repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) that can
  create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
  affected status info. See header of the script for usage instructions. Note that we plan to use
  [phenotips](https://phenotips.com/) in future to produce fully capable pedigree file. One could manually create them
  as well, but this could be error-prone.

- Input `BAM` and `VCF` files 

```
X/
├── bam
│   ├── X.bam
│   └── X.bam.bai
└── vcf
    ├── X.vcf.gz
    └── X.vcf.gz.tbi
```

```
X/
├── bam
│   ├── X.bam
│   └── X.bam.bai
├── configs
│   └── small_variant_caller
│       └── capture_regions.bed
└── vcf
    ├── X.vcf.gz
    └── X.vcf.gz.tbi
```

```
A/
├── bam
│   ├── A.bam
│   └── A.bam.bai
├── qc
│   ├── dedup
│   │   ├── A-1.metrics.txt
│   │   └── A-2.metrics.txt
│   ├── fastqc-raw
│   │   ├── ....
│   ├── fastqc-trimmed
│   │   ├── ....
│   ├── fastq_screen-trimmed
│   │   └── ....
│   └── multiqc_initial_pass
│       └── multiqc_sample_rename_config
│           └── A_rename_config.tsv
└── vcf
    ├── A.vcf.gz
    └── A.vcf.gz.tbi
```

- Output produced by [the small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
  This includes bam, vcf and QC output. Refer to [test sample dataset](.test/ngs-data/test_project/analysis/A), which is
  representative of the input required.

- QuaC workflow config file. Refer to [section here](#set-up-workflow-config-file) for more info.

- When run in exome mode, QuaC requires a capture-regions bed file at path
  `path_to_sample/configs/small_variant_caller/<capture_regions>.bed` for each sample.


### Example usage

```sh
# to quack on a WGS project, which also has prior QC data
PROJECT="Quack_Quack"
python src/run_quac.py \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --include_prior_qc \
      --allow_sample_renaming


# to quack on a WGS project, run in a medium slurm partition and write results to a dir of choice
PROJECT="Quack_This"
python src/run_quac.py \
      --slurm_partition medium \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT}/analysis"


# to quack on an exome project
PROJECT="Quack_That"
python src/run_quac.py \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome

# to quack on an exome project by providing path to that project
PROJECT="Quack_That"
python src/run_quac.py \
      --project_name $PROJECT \
      --projects_path "/path/to/project/${$PROJECT}/" \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome
```

### Output

QuaC results are stored at the path specified via option `--outdir` (default:
`$USER_SCRATCH/tmp/quac/results/test_project/analysis`).  Refer to the [testing's output](#expected-output-files) to
learn more about the output directory structure. Users may primarily be interested in the the aggregated QC results
produced by [multiqc](https://multiqc.info/), both at sample-level as well as at the project-level. These multiqc
reports also include summary of QuaC-Watch results.

Note that QuaC's output directory structure has been designed based on the output structure of the [small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

## Testing pipeline

The system-level testing implemented for this pipeline tests whether the pipeline runs from start to finish without any
error. This testing uses test datasets present in [`.test/ngs-data/test_project`](.test/ngs-data/test_project), which
reflects a test project containing four samples (2 with input needed when `include_priorQC` is used and 2 other samples
without priorQC data). [See here](.test/README.md) for more info on how these test datasets were created.

> **_NOTE:_**  This testing does not verify that pipeline's output are correct. Instead, its purpose is to ensure that
> pipeline runs from beginning to end without any execution error for the given test dataset.


### How to run

```sh
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26
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

Note: Use `PROJECT="project_1sample"` to test out a project with only one sample.

### Expected output files

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

Note: Certain tools (eg. indexcov and covviz) are not executed when QuaC is run in exome mode (`--exome`).


## Visualization of workflow

[Visualization of the pipeline](https://snakemake.readthedocs.io/en/stable/executing/cluster-cloud.html#visualization)
based on the test datasets are available in [directory `dag_pipeline`](./dag_pipeline/). Commands used to create this
visualization:

```sh
# open interactive node
srun --ntasks=1 --cpus-per-task=1 --mem-per-cpu=4096 --partition=express --pty /bin/bash

# setup environment
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26
conda activate quac

DAG_DIR="pipeline_visualized"

###### WGS mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/wgs_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/wgs_rulegraph.png"

###### Exome mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --exome \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/exome_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --exome \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/exome_rulegraph.png"
```

## Contributing

If you like to make changes to the source code, please see the [contribution guidelines](./CONTRIBUTING.md).

## Changelog

See [here](./Changelog.md).

## Repo owner

* *Mana*valan Gajapathy


```
cd /data/temporary-scratch/manag/tmp/quac/results/test_project_2_samples_wgs/analysis/ rm -rf
./*/qc/multiqc_*/ ./*/qc/quac_watch rm -rf ./project_level_qc/multiqc/
```

