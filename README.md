- [QuaC](#quac)
  - [What is QuaC?](#what-is-quac)
    - [QC tools included](#qc-tools-included)
  - [Pipeline installation](#pipeline-installation)
    - [Requirements](#requirements)
    - [Retrieve pipeline source code](#retrieve-pipeline-source-code)
  - [Environment Setup](#environment-setup)
    - [Requirements](#requirements-1)
    - [Create conda environment](#create-conda-environment)
  - [How to run QuaC](#how-to-run-quac)
    - [Requirements](#requirements-2)
    - [Set up workflow config file](#set-up-workflow-config-file)
      - [Prepare verifybamid datasets for exome analysis](#prepare-verifybamid-datasets-for-exome-analysis)
    - [Run pipeline](#run-pipeline)
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

QuaC is a pipeline, developed using snakemake, that runs several QC tools and summarizes results for WGS/WES samples
processed at CGDS. It is a companion pipeline that should be run after samples in a project are run through [CGDS's
small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

**Note**: While QuaC does the heavy lifting running several QC tools, the small variant caller pipeline also runs few QC
tools (fastqc, fastq-screen, picard's markduplicates). This setup was chosen deliberately as completely divorcing QC
from small variant caller pipeline would need some tricky, unnecessary implementations.

In short, QuaC performs the following:

- Runs various QC tools using data produced by the small variant caller pipeline
- Performs QC checkup based on the expected thresholds and summarizes the results
- Aggregates QC output produced here as well as those produced by the small variant caller pipeline using mulitqc, both
  at sample level and project level.

### QC tools included

QuaC quacks using the tools listed below:

| Tool                                                                                                                       | Use                                                                                           |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **BAM QC**                                                                                                                 |                                                                                               |
| [Qualimap](http://qualimap.conesalab.org/)                                                                                 | QCs alignment data in SAM/BAM files                                                           |
| [Picard-CollectMultipleMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics) | summarizes alignment metrics from a SAM/BAM file using several modules                        |
| [Picard-CollectWgsMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectWgsMetrics)           | Collects metrics about coverage and performance of whole genome sequencing (WGS) experiments. |
| [mosdepth](https://github.com/brentp/mosdepth)                                                                             | Fast BAM/CRAM depth calculation                                                               |
| [indexcov](https://github.com/brentp/goleft/tree/master/indexcov)                                                          | Estimate coverage from whole-genome bam or cram index                                         |
| [covviz](https://github.com/brwnj/covviz)                                                                                  | Identifies large, coverage-based anomalies                                                    |
| **VCF QC**                                                                                                                 |                                                                                               |
| [bcftools stats](https://samtools.github.io/bcftools/bcftools.html#stats)                                                  | Stats variants in VCF                                                                         |
| **Within-species contamination**                                                                                           |                                                                                               |
| [verifybamid](https://github.com/Griffan/VerifyBamID)                                                                      | Estimates within-species (i.e. cross-sample) contamination                                    |
| **Sex, ancestry and relatedness estimation**                                                                               |                                                                                               |
| [somalier](https://github.com/brentp/somalier)                                                                             | Estimation of sex, ancestry and relatedness                                                   |


In addition to this, QuaC also utilizes QC results produced by following tools as part of the [small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/small_variant_caller_pipeline/).

| Tool                                                                                                         | Use                                               |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)                                         | Performs QC checks on raw sequence data (fastq)   |
| [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)                             | Screens fastq for other-species contamination     |
| [Picard's MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates) | Determines level of read duplication on bam files |

## Pipeline installation

Installation simply requires fetching the source code.

### Requirements

- Git v2.0+
- CGDS GitLab access
- [SSH Key for access](https://docs.uabgrid.uab.edu/wiki/Cheaha_GettingStarted#Logging_in_to_Cheaha) to Cheaha cluster


### Retrieve pipeline source code

Pipeline installation simply requires fetching the source code. This repository use git submodules, which needs to be
pulled when cloning. Go to the directory of your choice and run the command below.

```sh
git clone -b master \
    --recurse-submodules \
    git@gitlab.rc.uab.edu:center-for-computational-genomics-and-data-science/sciops/pipelines/quac.git
```

Note that downloading this repository from GitLab, instead of cloning, may not fetch the submodules included.


## Environment Setup

After pipeline installation is completed, a conda environment needs to be created as described below. This conda
environment will install all necessary dependencies to run QuaC workflow.

### Requirements

- [Deep clone of repo](#pipeline-installation) created
- Anaconda/miniconda
    - Tested with Anaconda3/2020.02

### Create conda environment

Necessary dependencies for QuaC can installed in a conda environment as shown below:

```sh
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

1. Set up conda environment (see above)
2. Set up config files specifying paths required by QC tools used in the pipeline.

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
- Singularity
    - Tested with v3.5.2
    - Will be loaded as a module


Tools below are used in the pipeline, and snakemake automatically installs them in conda environments inside the
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

*This step is necessary only for exome samples.* [verifybamid](https://github.com/Griffan/VerifyBamID) has provided
auxiliary resource files, which are necessary for analysis. However, chromosome contigs do not include `chr` prefix in
their exome resource files, which are expected for our analyses at CGDS. Follow these steps to setup resource files with
`chr` prefix in their contig names.

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
                   [--outdir] [--exome] [--cluster_config] [--log_dir] [-e]
                   [-n] [-l] [--rerun_failed] [--slurm_partition]

Wrapper tool for QuaC pipeline.

optional arguments:
  -h, --help          show this help message and exit

QuaC workflow options:
  --project_name      Project name (default: None)
  --projects_path     Path where all projects are hosted. Do not include
                      project name here. (default:
                      /data/project/worthey_lab/projects/)
  --pedigree          Pedigree filepath. Must correspond to the project
                      supplied via --project_name (default: None)
  --outdir            Out directory path (default:
                      $USER_SCRATCH/tmp/quac/results/test_project/analysis)
  --exome             Flag to run in exome mode (default: False)

QuaC wrapper options:
  --cluster_config    Cluster config json file. Needed for snakemake to run
                      jobs in cluster. (default: /data/project/worthey_lab/pro
                      jects/experimental_pipelines/mana/quac/configs/cluster_c
                      onfig.json)
  --log_dir           Directory path where logs (both workflow's and
                      wrapper's) will be stored (default:
                      $USER_SCRATCH/tmp/quac/logs)
  -e , --extra_args   Pass additional custom args to snakemake. Equal symbol
                      is needed for assignment as in this example: -e='--
                      forceall' (default: None)
  -n, --dryrun        Flag to dry-run snakemake. Does not execute anything,
                      and just display what would be done. Equivalent to '--
                      extra_args "-n"' (default: False)
  -l, --run_locally   Flag to run the snakemake locally and not as a Slurm
                      job. Useful for testing purposes. (default: False)
  --rerun_failed      Number of times snakemake restarts failed jobs. This may
                      be set to >0 to avoid pipeline failing due to job fails
                      due to random SLURM issues (default: 0)
  --slurm_partition   Request a specific partition for the slurm resource
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
      --pedigree "path/to/project_duck/pedigree_file.ped"
```

*Note that options `--project_name` and `--pedigree` are required*. Only the samples that are supplied in pedigree file
via `--pedigree` will be processed by QuaC and all of these samples must belong to the same project. This repo also
includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) that can create a dummy pedigree file,
which will lack sex (unless project tracking sheet is provided), relatedness and affectedness info. See header of the
script for usage instructions. Note that we plan to use [phenotips](https://phenotips.com/) in future to produce fully
capable pedigree file. One could manually create them as well, but this would be error-prone.


**NOTE:**

Besides the basic features, wrapper script [`src/run_quac.py`](./src/run_quac.py) offers the following:

- Pass custom snakemake args using option `--extra_args`.
- Dry-run snakemake using flag `--dryrun`. Note that this is same as `--extra_args='-n'`.
- Override cluster config file passed to snakemake using `--cluster_config`.
- Run snakemake locally, instead of submitting it to Slurm, using `--run_locally`. Note that jobs from snakemake will
  still be submitted to Slurm.
- Reruns failed jobs once again by default. This may be modified using `--rerun_failed`.
- Override slurm partition used via `--slurm_partition`.


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
      --exome

# to quack on an exome project which is not in the default CGDS projects_path
python src/run_quac.py \
      --project_name UnusualCancers_CMGalluzi \
      --projects_path "/data/project/sloss/cgds_path_cmgalluzzi/" \
      --pedigree "data/raw/ped/UnusualCancers_CMGalluzi.ped" \
      --exome
```

## Output

TODO: Improve

QuaC results are stored at the path specified via option `--outdir` (default: `$USER_SCRATCH/tmp/quac/results`). This
includes aggregated QC results produced by [multiqc](https://multiqc.info/).


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

python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped -l -n
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

## Visualization of workflow

[Visualization of the pipeline](https://snakemake.readthedocs.io/en/stable/executing/cluster-cloud.html#visualization)
based on the test datasets are available in [directory `dag_pipeline`](./dag_pipeline/). Commands used to create this
visualization:

```sh
module reset
module load Anaconda3/2020.02
conda activate quac
DAG_DIR="pipeline_visualized"

###### WGS ######
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/wgs_dag.png"

python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project.ped \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/wgs_rulegraph.png"
```

## Contributing

If you like to make changes to the source code, please see the [contribution guidelines](./CONTRIBUTING.md).

## Changelog

See [here](./Changelog.md).
