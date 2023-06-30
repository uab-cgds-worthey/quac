# Installation & Configuration

This involves the following steps:

* Fetch the source code for QuaC
* Set up necessary configurations
* Create the conda environment `quac`
* Test run to check QuaC works as expected

## Requirements

Tools necessary to install and run QuaC:

- Linux OS. Tested in Red Hat Enterprise Linux v7.9
- Git
- Anaconda/miniconda. Tested using Anaconda3/2020.02
- [Singularity](https://apptainer.org/) is required but not provided. Tested using Singularity v3.5.2.
- [SLURM](https://slurm.schedmd.com/)
    - Needed if you will be supplying `--snakemake_cluster_config` and/or `--cli_cluster_config` to `src/run_quac.py`.

!!! note "Cheaha users only"

    * Conda is Available as module in Cheaha - `Anaconda3/2020.02`
    * Singularity is available as module in Cheaha - `Singularity/3.5.2-GCC-5.4.0-2.26`


## Retrieve QuaC source code

Go to the directory of your choice and run the command below.

```sh
git clone https://github.com/uab-cgds-worthey/quac.git
```

## Configuration

### Workflow config 

QuaC requires a workflow config file in yaml format (default: `configs/workflow.yaml`). It provides following info to
QuaC: 

- Filepaths to necessary dataset dependencies required by certain QC tools used in QuaC.
    - ** We provide `src/setup_dependency_datasets.sh` to download and set up these datasets.**
    - To run this script, change into QuaC directory and use command: `bash src/setup_dependency_datasets.sh`. Output
      will be saved at `data/external/dependency_datasets`.
- Hardware resource configs for certain QC tools used in snakemake piepline

!!! tip 

    Custom workflow config file can be provided to QuaC via `--workflow_config`.

### SLURM config

QuaC's wrapper script `src/run_quac.py` allows you to submit jobs to SLURM scheduler at two levels:

* using `--cli_cluster_config` - submits the script that will run the snakemake workflow as a SLURM job
* using `--snakemake_cluster_config` - allows snakemake to submit jobs to SLURM

These config files specify the resources to be requested when submitting the job to SLURM.

### a. Set up `--cli_cluster_config` config file

We provide a template file `configs/cli_cluster_config.json` to use with `--cli_cluster_config`. Its contents are shown
below:

```json
{!configs/cli_cluster_config.json!}
```

As SLURM configuration in your cluster environment likely differs from other HPC clusters, you may need to modify this
template file to suit your SLURM setup.

For example, some SLURM might need `account` info when submitting jobs. So you may modify the config file, assuming
other args are acceptable, as:

```json hl_lines="2"
{
    "account": "your_account_name",     <----- edited line
    "partition": "express",
    "ntasks": "1",
    "time": "02:00:00",
    "cpus-per-task": "1",
    "mem-per-cpu": "8G"
}
```

If your SLURM requires `qos` and doesn't use `partition`, config file can be modified as:

```json
{
    "qos": "qos_tag",           <----- edited line
    // "partition": "express",  <----- edited line
    "ntasks": "1",
    "time": "02:00:00",
    "cpus-per-task": "1",
    "mem-per-cpu": "8G"
}
```

!!! tip 

    If you are having difficulty setting up SLURM configs, you may want to consult your institutional support team for assistance.


### b. Set up `--snakemake_cluster_config` config file

We provide a template file `configs/snakemake_cluster_config.json` to use with `--snakemake_cluster_config`. Its
contents are shown below:

```json
{!configs/snakemake_cluster_config.json!}
```

In this file, `__default__` specifies the default resources to be requested for jobs submitted by snakemake to SLURM,
and the rest (eg. `qualimap_bamqc`) bypass certain defaults and instead specifies snakemake rule specific resources.

Just [as discussed earlier](#a-set-up-cli_cluster_config-config-file), you may need to modify this template file to suit
your SLURM setup. For example, if your SLURM requires specifying `account` info when submitting jobs, it can be
supplied, assuming other args are acceptable, as:

```json
{
    "__default__": {
        "account": "your_account_name",       <----- edited line
        "ntasks": 1,
        "partition": "express",
        "cpus-per-task": "{threads}",
        "mem-per-cpu": "8G",
        "job-name": "QuaC.{rule}.{jobid}",
        "output": "{RULE_LOGS_PATH}/{rule}-%j.log"
    },
    ...
    ...
}
```

Or, if your SLURM requires `qos` and doesn't use `partition`, config file can be modified as:

```json 
{
    "__default__": {
        "ntasks": 1,
        "qos": "qos_tag1",           <----- edited line
        "cpus-per-task": "{threads}",
        "mem-per-cpu": "8G",
        "job-name": "QuaC.{rule}.{jobid}",
        "output": "{RULE_LOGS_PATH}/{rule}-%j.log"
    },
    "qualimap_bamqc": {
        "qos": "qos_tag2",           <----- edited line
        "mem-per-cpu": "{params.java_mem}"
    },
    "picard_collect_multiple_metrics": {
        "qos": "qos_tag2"           <----- edited line
    },
    ...
    ...
}
```

!!! tip 

    If you are having difficulty setting up SLURM configs, you may want to consult your institutional support team for assistance.


## Create conda environment

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

## Test run QuaC

When you have completed all the installation and configuration steps described so far, it is time to test run QuaC to
check it runs as expected using the commands below.  

```sh
# Be sure conda and singularity are available in your enviroment
# Below snippet is for Cheaha users only.
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

# specify slurm config files to use
USE_SLURM="--cli_cluster_config configs/cli_cluster_config.json 
           --snakemake_cluster_config configs/snakemake_cluster_config.json"

PROJECT_CONFIG="project_2samples"
PRIOR_QC_STATUS="no_priorQC"

python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/${PRIOR_QC_STATUS}/${PROJECT_CONFIG}.ped" \
      --outdir "data/quac/results/test_${PROJECT_CONFIG}_wgs-${PRIOR_QC_STATUS}/analysis" \
      --quac_watch_config "configs/quac_watch/wgs_quac_watch_config.yaml" \
      --workflow_config "configs/workflow.yaml" \
      $USE_SLURM
```

!!! info

    In case you run into an error, please double check that configuration files were properly set up.

Note that the first time you run the snakemake workflow, it will first retrieve the necessary singularity images and
then run the QC jobs. This process may take about 30mins to 1hr to complete the job. If it takes way longer than an
hour, please check the log files (specified using `--log_dir`) and your SLURM jobs to identify the cause.

