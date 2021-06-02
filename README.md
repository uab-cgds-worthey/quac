- [QuaC](#quac)
  - [What is QuaC?](#what-is-quac)
    - [QC tools included](#qc-tools-included)
    - [CGDS QC-checkup](#cgds-qc-checkup)
  - [Installation](#installation)
    - [Requirements](#requirements)
    - [Retrieve pipeline source code](#retrieve-pipeline-source-code)
    - [Create conda environment](#create-conda-environment)
  - [How to run QuaC](#how-to-run-quac)
    - [Requirements](#requirements-1)
    - [Set up workflow config file](#set-up-workflow-config-file)
      - [Prepare verifybamid datasets for exome analysis](#prepare-verifybamid-datasets-for-exome-analysis)
    - [Run pipeline](#run-pipeline)
    - [Create singularity+conda environments for tools used in QuaC pipeline](#create-singularityconda-environments-for-tools-used-in-quac-pipeline)
    - [Input requirements](#input-requirements)
    - [Example usage](#example-usage)
    - [Output](#output)
  - [Testing pipeline](#testing-pipeline)
    - [How to run](#how-to-run)
    - [Expected output files](#expected-output-files)
  - [Visualization of workflow](#visualization-of-workflow)
  - [Contributing](#contributing)
  - [Changelog](#changelog)

# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

## What is QuaC?

QuaC is a snakemake-based pipeline that runs several QC tools and summarizes results for WGS/WES samples processed at
CGDS using internally defined QC thresholds. It is a companion pipeline that should be run after samples in a project
are run through [CGDS's small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

In short, QuaC performs the following:

- Runs various QC tools using data produced by the small variant caller pipeline
- Performs QC checkup based on the expected thresholds and summarizes the results for easy consumption
- Aggregates QC output produced here as well as those by the small variant caller pipeline using mulitqc, both at sample
  level and project level

**Note**:

1. While QuaC does the heavy lifting in performing QC, the small variant caller pipeline also runs few QC tools (fastqc,
   fastq-screen, picard's markduplicates). This setup was chosen deliberately for pragmatic reasons.
2. *Use QC-checkup results with extreme caution when run in exome mode.* Though QuaC can be run in exome mode,
   QC-checkup thresholds utilized are not yet as reliable as that used for WGS datasets.


### QC tools included

QuaC quacks using the tools listed below:

| Tool                                                                                                                       | Use                                                                                           |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| *BAM QC*                                                                                                                   |                                                                                               |
| [Qualimap](http://qualimap.conesalab.org/)                                                                                 | QCs alignment data in SAM/BAM files                                                           |
| [Picard-CollectMultipleMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics) | summarizes alignment metrics from a SAM/BAM file using several modules                        |
| [Picard-CollectWgsMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectWgsMetrics)           | Collects metrics about coverage and performance of whole genome sequencing (WGS) experiments. |
| [mosdepth](https://github.com/brentp/mosdepth)                                                                             | Fast BAM/CRAM depth calculation                                                               |
| [indexcov](https://github.com/brentp/goleft/tree/master/indexcov)                                                          | Estimate coverage from whole-genome bam or cram index (Not run in exome mode)                 |
| [covviz](https://github.com/brwnj/covviz)                                                                                  | Identifies large, coverage-based anomalies (Not run in exome mode)                            |
| *VCF QC*                                                                                                                   |                                                                                               |
| [bcftools stats](https://samtools.github.io/bcftools/bcftools.html#stats)                                                  | Stats variants in VCF                                                                         |
| *Within-species contamination*                                                                                             |                                                                                               |
| [verifybamid](https://github.com/Griffan/VerifyBamID)                                                                      | Estimates within-species (i.e. cross-sample) contamination                                    |
| *Sex, ancestry and relatedness estimation*                                                                                 |                                                                                               |
| [somalier](https://github.com/brentp/somalier)                                                                             | Estimation of sex, ancestry and relatedness                                                   |


In addition to this, QuaC also utilizes QC results produced by following tools as part of the [small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/small_variant_caller_pipeline/).

| Tool                                                                                                         | Use                                               |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)                                         | Performs QC checks on raw sequence data (fastq)   |
| [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)                             | Screens fastq for other-species contamination     |
| [Picard's MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates) | Determines level of read duplication on bam files |


### CGDS QC-checkup

After running all the QC tools for samples, QuaC summarizes if samples have passed the QC thresholds (defined via config
file [`wgs_qc_checkup_config.yaml`](configs/qc_checkup/wgs_qc_checkup_config.yaml); can be user-configured), both at the sample
level as well as project level. This summary makes it easy to quickly review if sample or samples have sufficient
quality and highlight samples that need further review.

## Installation

Installation requires

- fetching the source code
- creating the conda environment

### Requirements

- Git v2.0+
- CGDS GitLab access
- [SSH Key for access](https://docs.uabgrid.uab.edu/wiki/Cheaha_GettingStarted#Logging_in_to_Cheaha) to Cheaha cluster
- Anaconda/miniconda
    - Tested with Anaconda3/2020.02

### Retrieve pipeline source code

This repository use git submodules, which need to be pulled when cloning. Go to the directory of your choice and run the
command below.

```sh
git clone -b master \
    --recurse-submodules \
    git@gitlab.rc.uab.edu:center-for-computational-genomics-and-data-science/sciops/pipelines/quac.git
```

Note that downloading this repository from GitLab, instead of cloning, may not fetch the submodules included.


### Create conda environment

Conda environment will install all necessary dependencies, including snakemake, to run the QuaC workflow.

```sh
cd /path/to/quac/repo

module reset
module load Anaconda3/2020.02

# create conda environment. Needed only the first time.
conda env create --file configs/env/quac.yaml
# activate conda environment
conda activate quac

# if you need to update the existing environment
conda env update --file configs/env/quac.yaml
```


## How to run QuaC

In order to run the QuaC pipeline, user needs to

1. Install the pipeline and set up the conda environment ([see above](#installation))
2. Set up config files specifying paths required by QC tools used in the pipeline.
3. Run QuaC pipeline just to create singularity+conda environments using testing dataset (optional)

### Requirements

***Direct***

- Snakemake
    - Tested with v6.0.5
    - Gets installed as part of conda environment
- Python
    - Tested with v3.6.3
    - Gets installed as part of conda environment
- slurmpy
    - Tested with v0.0.8
    - Gets installed as part of conda environment

***Indirect***

- Anaconda/miniconda
    - Tested with Anaconda3/2020.02
    - Available as module from cheaha
- Singularity
    - Tested with v3.5.2
    - Will be loaded as a module when running QuaC

Tools below are used in the QuaC pipeline, and snakemake automatically installs them in conda environments inside the
singularity container. Therefore, they don't need to be manually installed. For tool versions used, refer to the
snakemake rules.

- qualimap
- picard
- mosdepth
- indexcov
- covviz
- bcftools
- verifybamid
- somalier
- multiqc


### Set up workflow config file

QuaC requires a workflow config file in yaml format (`configs/workflow.yaml`), which provides filepaths to necessary
dependencies required by certain QC tools. Their format should look like:

```yaml
ref: "path to ref genome path"
somalier:
    sites: "path to somalier's site file"
    labels_1kg: "path to somalier's ancestry-labels-1kg file"
    somalier_1kg: "dirpath to somalier's 1kg-somalier files"
verifyBamID:
    svd_dat_wgs: "path to WGS resources .dat files"
    svd_dat_exome: "path to exome resources .dat files"
```

#### Prepare verifybamid datasets for exome analysis

*This step is necessary only if QuaC will be run in exome mode (`--exome`).*
[verifybamid](https://github.com/Griffan/VerifyBamID) has provided auxiliary resource files, which are necessary for
analysis. However, chromosome contigs do not include `chr` prefix in their exome resource files, which are expected for
our analyses at CGDS. Follow these steps to setup resource files with `chr` prefix in their contig names.

```sh
# cd into exome resources dir
cd <path-to>/VerifyBamID-2.0.1/resource/exome/
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.bed > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.bed
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.mu > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.mu
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.UD 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.UD
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.V 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.V
```

### Run pipeline

After activating the conda environment, QuaC pipeline can be run using the wrapper script `src/run_quac.py`. Here are
all the options available:

```sh
$ ./src/run_quac.py -h
usage: run_quac.py [-h] [--project_name] [--projects_path] [--pedigree]
                   [--qc_checkup_config] [--workflow_config] [--outdir]
                   [--exome] [--cluster_config] [--log_dir] [-e] [-n] [-l]
                   [--rerun_failed] [--slurm_partition]

Wrapper tool for QuaC pipeline.

optional arguments:
  -h, --help            show this help message and exit

QuaC workflow options:
  --project_name        Project name (default: None)
  --projects_path       Path where all projects are hosted. Do not include
                        project name here. (default:
                        /data/project/worthey_lab/projects/)
  --pedigree            Pedigree filepath. Must correspond to the project
                        supplied via --project_name (default: None)
  --qc_checkup_config   YAML config path specifying QC thresholds for QC
                        checkup (default:
                        configs/qc_checkup/wgs_qc_checkup_config.yaml)
  --workflow_config     YAML config path specifying filepath to dependencies
                        of tools used in QuaC (default: configs/workflow.yaml)
  --outdir              Out directory path (default:
                        $USER_SCRATCH/tmp/quac/results/test_project/analysis)
  --exome               Flag to run in exome mode. WARNING: Please provide
                        appropriate configs via --qc_checkup_config. (default:
                        False)

QuaC wrapper options:
  --cluster_config      Cluster config json file. Needed for snakemake to run
                        jobs in cluster. (default: /data/project/worthey_lab/p
                        rojects/experimental_pipelines/mana/quac/configs/clust
                        er_config.json)
  --log_dir             Directory path where logs (both workflow's and
                        wrapper's) will be stored (default:
                        $USER_SCRATCH/tmp/quac/logs)
  -e , --extra_args     Pass additional custom args to snakemake. Equal symbol
                        is needed for assignment as in this example: -e='--
                        forceall' (default: None)
  -n, --dryrun          Flag to dry-run snakemake. Does not execute anything,
                        and just display what would be done. Equivalent to '--
                        extra_args "-n"' (default: False)
  -l, --run_locally     Flag to run the snakemake locally and not as a Slurm
                        job. Useful for testing purposes. (default: False)
  --rerun_failed        Number of times snakemake restarts failed jobs. This
                        may be set to >0 to avoid pipeline failing due to job
                        fails due to random SLURM issues (default: 1)
  --slurm_partition     Request a specific partition for the slurm resource
                        allocation for QuaC workflow. Available partitions in
                        Cheaha are: express(max 2 hrs), short(max 12 hrs),
                        medium(max 50 hrs), long(max 150 hrs) (default: short)
```

To run the wrapper script, which in turn will execute the QuaC pipeline:

```sh
module reset
module load Anaconda3/2020.02
conda activate quac

python src/run_quac.py \
      --project_name PROJECT_DUCK \
      --pedigree "path/to/lake/with/pedigree_file.ped"
```

**NOTE:**

Besides the basic features, wrapper script [`src/run_quac.py`](./src/run_quac.py) offers the following:

- Pass custom snakemake args using option `--extra_args`.
- Dry-run snakemake using flag `--dryrun`. Note that this is same as `--extra_args='-n'`.
- Override cluster config file passed to snakemake using `--cluster_config`.
- Run snakemake locally, instead of submitting it to Slurm, using `--run_locally`. Note that jobs from snakemake will
  still be submitted to Slurm.
- Reruns failed jobs once again by default. This may be modified using `--rerun_failed`.
- Override slurm partition used via `--slurm_partition`.


### Create singularity+conda environments for tools used in QuaC pipeline

All the jobs initiated by QuaC would be run inside a conda environment, which themselves were created inside a
singularity container. It may be a good idea to create these environments even before they are run with actual samples.
While this step is optional, this will ensure that there will not be any conflicts when running multiple instances of
the pipeline.

Running the commands below will submit a slurm job to just create these singularity+conda environments. Note that this
slurm job will exit right after creating the environments, and it will not run any QC analyses on the input samples
provided.

```sh
module reset
module load Anaconda3/2020.02
conda activate quac

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/project.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_project_wgs/analysis" \
      -e="--conda-create-envs-only"
```


### Input requirements

- Pedigree file supplied via `--pedigree`. Only the samples that are supplied in pedigree file will be processed by QuaC
  and all of these samples must belong to the same project. This repo also includes a handy script
  [`src/create_dummy_ped.py`](src/create_dummy_ped.py) that can create a dummy pedigree file, which will lack sex
  (unless project tracking sheet is provided), relatedness and affected status info. See header of the script for usage
  instructions. Note that we plan to use [phenotips](https://phenotips.com/) in future to produce fully capable pedigree
  file. One could manually create them as well, but this would be error-prone.
- Output produced by [the small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
  This includes bam, vcf and QC output. Refer to [test sample dataset](.test/ngs-data/test_project/analysis/A), which is
  representative of the input required.
- [QuaC config file](#set-up-workflow-config-file)
- When run in exome mode, QuaC requires a capture-regions bed file at path
  `path_to_sample/configs/small_variant_caller/<capture_regions>.bed`.


### Example usage

```sh
# to quack on a WGS project
python src/run_quac.py \
      --project_name CF_CFF_PFarrell \
      --pedigree "data/raw/ped/CF_CFF_PFarrell.ped"

# to quack on a WGS project and write results to a dir of choice
PROJECT="CF_CFF_PFarrell"
python src/run_quac.py \
      --slurm_partition medium \
      --project_name ${PROJECT} \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --outdir "/data/scratch/manag/tmp/quac/results/test_${PROJECT}/analysis"

# to quack on an exome project
python src/run_quac.py \
      --project_name HCC \
      --pedigree "data/raw/ped/HCC.ped" \
      --qc_checkup_config "configs/qc_checkup/exome_qc_checkup_config.yaml" \
      --exome

# to quack on an exome project which is not in the default CGDS projects_path
python src/run_quac.py \
      --project_name UnusualCancers_CMGalluzi \
      --projects_path "/data/project/sloss/cgds_path_cmgalluzzi/" \
      --pedigree "data/raw/ped/UnusualCancers_CMGalluzi.ped" \
      --qc_checkup_config "configs/qc_checkup/exome_qc_checkup_config.yaml" \
      --exome
```

### Output

QuaC results are stored at the path specified via option `--outdir` (default:
`$USER_SCRATCH/tmp/quac/results/test_project/analysis`).  Refer to the [testing's output](#expected-output-files) to
learn about output directory structure. Most important output files are aggregated QC results produced by
[multiqc](https://multiqc.info/), both at sample-level as well as at the project-level. These multiqc reports also
include summary of QC-checkup results.

Note that QuaC's output directory structure takes the output structure of the small variant caller pipeline.

## Testing pipeline

The system-level testing implemented for this pipeline tests whether the pipeline runs from start to finish without any
error. This testing uses test datasets present in [`.test/ngs-data/test_project`](.test/ngs-data/test_project), which
reflects a test project containing two samples. [See here](.test/README.md) for more info on how these test datasets
were created.

> **_NOTE:_**  This testing does not verify that pipeline's output are correct. Instead, its purpose is just to ensure
> that pipeline runs from beginning to end without any execution error for the given test dataset.


### How to run

```sh
module reset
module load Anaconda3/2020.02
conda activate quac

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/project.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_project_wgs/analysis"

# Exome mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/project.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_project_exome/analysis" \
      --qc_checkup_config "configs/qc_checkup/exome_qc_checkup_config.yaml" \
      --exome
```

### Expected output files

```sh
$ tree $USER_SCRATCH/tmp/quac/results/test_project/ -d -L 4
/data/scratch/manag/tmp/quac/results/test_project/
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
    │       ├── qc_checkup
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

Certain tools (eg. indexcov and covviz) are not executed when QuaC is run in exome mode (`--exome`).


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
conda activate quac
DAG_DIR="pipeline_visualized"

###### WGS mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/wgs_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/wgs_rulegraph.png"

###### Exome mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --exome \
      --qc_checkup_config "configs/qc_checkup/exome_qc_checkup_config.yaml" \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/exome_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --exome \
      --qc_checkup_config "configs/qc_checkup/exome_qc_checkup_config.yaml" \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/exome_rulegraph.png"
```

## Contributing

If you like to make changes to the source code, please see the [contribution guidelines](./CONTRIBUTING.md).

## Changelog

See [here](./Changelog.md).
