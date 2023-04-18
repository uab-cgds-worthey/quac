# Requirements and Configs

In order to run the QuaC pipeline, user needs to

1. [Install the pipeline and set up the conda environment](./installation.md).
2. Set up config files specifying paths and hardware resources required by QC tools used in the pipeline.
3. (Optional) Run QuaC pipeline just to create singularity environments using the system testing datasets.

## Requirements

- [Singularity](https://apptainer.org/) is required but not provided. QuaC pipeline was developed and tested using Singularity v3.5.2.

!!! note "Cheaha users only"

    Singularity is available as module in Cheaha - `Singularity/3.5.2-GCC-5.4.0-2.26`

- Following dependencies are installed as part of the `quac` conda environment. See [installation](./installation.md) for info on creating this conda environment.
    - Snakemake-minimal v6.0.5
    - Python v3.6.13
    - Slurmpy v0.0.8


- Tools below are used in the QuaC pipeline, and Snakemake automatically installs them as needed during QuaC execution. Therefore, they don't need to be manually installed. For tool versions used, refer to the Snakemake rules.
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

QuaC requires a workflow config file in yaml format (default: `configs/workflow.yaml`). It provides following info to QuaC: 

- Filepaths to necessary dataset dependencies required by certain QC tools used in QuaC.
    - Use script `src/setup_dependency_datasets.sh` to download and set up these datasets. 
    - To run this script, use command: `bash src/setup_dependency_datasets.sh`. Output will be saved at `data/external/dependency_datasets`.
- Hardware resource configs
- Slurm partition resources

!!! tip
    Custom workflow config file can be provided to QuaC via `--workflow_config`.


## Pull Singularity images [Optional]

All the jobs initiated by QuaC's snakemake workflow will be run in corresponding Singularity environment, and snakemake automatically retrieves the Singularity images as needed. As part of the initial QuaC setup, it may be a good idea to run _only one of the_ [system testing](./system_testing.md) jobs, and this will retrieve and set up all the necessary Singularity images. This is an optional step, but highly recommended if you plan to run multiple instances of QuaC parallely. 

