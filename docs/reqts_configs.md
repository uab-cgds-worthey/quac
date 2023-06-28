# Requirements and Configs

In order to run the QuaC pipeline, user needs to

1. [Install the pipeline and set up the conda environment](./installation.md).
2. Set up workflow config files specifying paths and hardware resources required by QC tools used in the pipeline.
3. Set up cluster config files if you will be submitting jobs to SLURM cluster.
4. (Optional) Run QuaC pipeline just to create singularity environments using the system testing datasets.

## Requirements

- Linux OS. QuaC was developed and tested in Red Hat Enterprise Linux  v7.9

- [Singularity](https://apptainer.org/) is required but not provided. QuaC pipeline was developed and tested using
  Singularity v3.5.2.

!!! note "Cheaha users only"

    Singularity is available as module in Cheaha - `Singularity/3.5.2-GCC-5.4.0-2.26`

- [SLURM](https://slurm.schedmd.com/)
    - Optional. Needed only if you will be supplying `--snakemake_cluster_config` and/or `--cli_cluster_config` to `src/run_quac.py`.

- Following dependencies are installed as part of the `quac` conda environment. See [installation](./installation.md)
  for info on creating this conda environment.
    - Snakemake-minimal v6.0.5
    - Python v3.6.13
    - Slurmpy v0.0.8

- Tools below are used in the QuaC pipeline, and Snakemake automatically installs them as needed during QuaC execution.
  Therefore, they don't need to be manually installed. For tool versions used, refer to the Snakemake rules.
    - qualimap
    - picard
    - mosdepth
    - indexcov
    - covviz
    - bcftools
    - verifybamid
    - somalier
    - multiqc


## Set up workflow config file

QuaC requires a workflow config file in yaml format (default: `configs/workflow.yaml`). It provides following info to
QuaC: 

- Filepaths to necessary dataset dependencies required by certain QC tools used in QuaC.
    - **Use script `src/setup_dependency_datasets.sh` to download and set up these datasets.**
    - To run this script, use command: `bash src/setup_dependency_datasets.sh`. Output will be saved at
      `data/external/dependency_datasets`.
- Hardware resource configs for certain QC tools used in snakemake piepline

!!! tip 

    Custom workflow config file can be provided to QuaC via `--workflow_config`.


## Set up SLURM cluster config file

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

As SLURM configuration in your cluster environment likely differs from other HPC clusters, you may need to modify this template
file to suit your SLURM setup.

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

## Pull Singularity images [Optional]

All the jobs initiated by QuaC's snakemake workflow will be run in corresponding Singularity environment, and snakemake
automatically retrieves the Singularity images as needed. As part of the initial QuaC setup, it may be a good idea to
run _only one of the_ [system testing](./system_testing.md) jobs, and this will retrieve and set up all the necessary
Singularity images. This is an optional step, but highly recommended if you plan to run multiple instances of QuaC
parallely. 

