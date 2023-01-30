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


### QC tools utilized

QuaC quacks using the tools listed below:

| Tool                                                                                                                       | Use                                                                                           |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| *BAM QC*                                                                                                                   |                                                                                               |
| [Qualimap](http://qualimap.conesalab.org/)                                                                                 | QCs alignment data in SAM/BAM files                                                           |
| [Picard-CollectMultipleMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics) | Summarizes alignment metrics from a SAM/BAM file using several modules                        |
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

### Optional tools' results consumption

In addition to the above tools, optionally QuaC can also utilize QC results produced by the tools below when run with
flag `--include_prior_qc`. At CGDS, these files are produced as part of the [small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

| Tool                                                                                                         | Use                                               |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)                                         | Performs QC checks on raw sequence data (fastq)   |
| [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)                             | Screens fastq for other-species contamination     |
| [Picard's MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates) | Determines level of read duplication on bam files |


### QuaC-Watch

QuaC includes a tool called QuaC-Watch. After running all the QC tools for samples, QuaC-Watch summarizes if samples
have passed the configurable QC thresholds defined using config files (available at
[`configs/quac_watch/`](./configs/quac_watch/)), both at the sample level as well as project level. This summary makes
it easy to quickly review whether sample or samples are of sufficient quality and highlight samples that need further
review.

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
    - Available as module from cheaha at UAB

### Retrieve pipeline source code

Go to the directory of your choice and run the command below.

```sh
git clone -b master \
    git@gitlab.rc.uab.edu:center-for-computational-genomics-and-data-science/sciops/pipelines/quac.git
```


### Create conda environment

Conda environment will install all necessary dependencies, including snakemake, to run the QuaC workflow.

```sh
cd /path/to/quac/repo

# For use only at Cheaha in UAB. Load conda into environment.
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
3. Run QuaC pipeline just to create singularity+conda environments using the testing dataset (optional)

### Requirements

***Direct***

- Snakemake-minimal
    - Tested with v6.0.5
    - Gets installed as part of conda environment
- Python
    - Tested with v3.6.13
    - Gets installed as part of conda environment
- slurmpy
    - Tested with v0.0.8
    - Gets installed as part of conda environment

***Indirect***

- Anaconda/miniconda
    - Tested with Anaconda3/2020.02
    - Available as module from cheaha at UAB
- Singularity
    - Tested with v3.5.2
    - Available as module from cheaha at UAB

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

QuaC requires a workflow config file in yaml format (default is [`configs/workflow.yaml`](./configs/workflow.yaml)),
which provides:

- Filepaths to necessary dataset dependencies required by certain QC tools
- Hardware resource configs

Custom workflow config file can be provided to QuaC via `--workflow_config`.

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
$ python src/run_quac.py -h
usage: run_quac.py [-h] [--project_name] [--projects_path] [--pedigree]
                   [--quac_watch_config] [--workflow_config] [--outdir]
                   [--exome] [--include_prior_qc] [--allow_sample_renaming]
                   [--cluster_config] [--log_dir] [-e] [-n] [-l]
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
  --quac_watch_config   YAML config path specifying QC thresholds for QuaC-
                        Watch (default:
                        configs/quac_watch/wgs_quac_watch_config.yaml)
  --workflow_config     YAML config path specifying filepath to dependencies
                        of tools used in QuaC (default: configs/workflow.yaml)
  --outdir              Out directory path (default:
                        $USER_SCRATCH/tmp/quac/results/test_project/analysis)
  --exome               Flag to run the workflow in exome mode. WARNING:
                        Please provide appropriate configs via
                        --quac_watch_config. (default: False)
  --include_prior_qc    Flag to additionally use prior QC data as input. See
                        documentation for more info. (default: False)
  --allow_sample_renaming
                        Flag to allow sample renaming in MultiQC report. See
                        documentation for more info. (default: False)

QuaC wrapper options:
  --cluster_config      Cluster config json file. Needed for snakemake to run
                        jobs in cluster. (default: configs/cluster_config.json)
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

Minimal example to run the wrapper script, which in turn will execute the QuaC pipeline:

```sh
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26
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
singularity container. It may be a good idea to create these environments before they are run with actual samples.
While this step is optional, this will ensure that there will not be any conflicts when running multiple instances of
the pipeline.

Running the commands below will submit a slurm job to just create these singularity+conda environments. Note that this
slurm job will exit right after creating the environments, and it will not run any QC analyses on the input samples
provided.

```sh
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26
conda activate quac

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/no_priorQC/project_2samples.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_project_wgs/analysis" \
      -e="--conda-create-envs-only"
```


### Input requirements

- Pedigree file supplied via `--pedigree`. Only the samples that are supplied in pedigree file will be processed by QuaC
  and all of these samples must belong to the same project.
  - *For CGDS use only*: This repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) that can
  create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
  affected status info. See header of the script for usage instructions. Note that we plan to use
  [phenotips](https://phenotips.com/) in future to produce fully capable pedigree file. One could manually create them
  as well, but this could be error-prone.
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
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/wgs_quac_watch_config.yaml" 

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
      --quac_watch_config "configs/quac_watch/wgs_quac_watch_config.yaml" \
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



