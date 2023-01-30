# Requirements and Configs

In order to run the QuaC pipeline, user needs to

1. [Install the pipeline and set up the conda environment](./installation.md).
2. Set up config files specifying paths and hardware resources required by QC tools used in the pipeline.
3. (Optional) Run QuaC pipeline just to create singularity+conda environments using the system testing datasets.

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

QuaC requires a workflow config file in yaml format, which provides: 

- Filepaths to necessary dataset dependencies required by certain QC tools
- Hardware resource configs
- [TODO] Slurm resources

Refer to the default config file [`configs/workflow.yaml`](../configs/workflow.yaml) to set up your own.

!!! tip
    Custom workflow config file can be provided to QuaC via `--workflow_config`.


### Prepare verifybamid datasets for exome mode

*This step is necessary only if QuaC will be run in exome mode (`--exome`).*
[verifybamid](https://github.com/Griffan/VerifyBamID) has provided auxiliary resource files, which are necessary for
analysis. However, chromosome contigs do not include `chr` prefix in their exome resource files, which are expected for
our analyses at CGDS. Follow these steps to setup resource files with `chr` prefix in their contig names.

```sh
# retrieve
# cd into exome resources dir (available at VerifyBamID github repo)
cd <path-to>/VerifyBamID-2.0.1/resource/exome/
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.bed > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.bed
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.mu > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.mu
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.UD 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.UD
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.V 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.V
```

## Create singularity+conda environments for tools used in QuaC pipeline

All the jobs initiated by QuaC's snakemake workflow would be run in Singularity or Singularity+Conda environment. It may
be a good idea to create these environments before they are run with actual samples. While this step is optional, this
will ensure that there will not be any conflicts when running multiple instances of the pipeline.

Running the commands below will submit a slurm job to just create these Singularity/Singularity+conda environments. Note
that this slurm job will exit right after creating the environments, and it will not run any QC analyses on the input
samples provided.

```sh
# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

# WGS mode
python src/run_quac.py \
      --project_name test_project \
      --projects_path ".test/ngs-data/" \
      --pedigree ".test/configs/no_priorQC/project_2samples.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_project_wgs/analysis" \
      -e="--conda-create-envs-only"
```
