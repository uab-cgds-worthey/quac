# Requirements and Configs

In order to run the QuaC pipeline, user needs to

1. [Install the pipeline and set up the conda environment](./installation.md).
2. Set up workflow config files specifying paths and hardware resources required by QC tools used in the pipeline.
3. Set up cluster config files if you will be submitting jobs to SLURM cluster.
4. (Optional) Run QuaC pipeline just to create singularity environments using the system testing datasets.

## Requirements

- Linux OS. QuaC was developed and tested in Red Hat Enterprise Linux  v7.9



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




## Set up SLURM cluster config file




## Pull Singularity images [Optional]

All the jobs initiated by QuaC's snakemake workflow will be run in corresponding Singularity environment, and snakemake
automatically retrieves the Singularity images as needed. As part of the initial QuaC setup, it may be a good idea to
run _only one of the_ [system testing](./system_testing.md) jobs, and this will retrieve and set up all the necessary
Singularity images. This is an optional step, but highly recommended if you plan to run multiple instances of QuaC
parallely. 

