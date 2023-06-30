# How to run QuaC pipeline

After [proper installation and configuration](./installation_configuration.md), QuaC pipeline can be run using the wrapper/CLI (command line interface) tool `src/run_quac.py`.

## Command line interface

```sh
$ python src/run_quac.py -h
usage: run_quac.py [-h] [--project_name] [--projects_path] [--pedigree]
                   [--quac_watch_config] [--workflow_config]
                   [--snakemake_cluster_config] [--outdir] [--tmp_dir]
                   [--exome] [--include_prior_qc] [--allow_sample_renaming]
                   [-e] [-n] [--cli_cluster_config] [--log_dir]

Command line interface to QuaC pipeline.

optional arguments:
  -h, --help            show this help message and exit

QuaC workflow options:
  --project_name        Project name (default: None)
  --projects_path       Path where all projects are hosted. Do not include
                        project name here. (default: None)
  --pedigree            Pedigree filepath. Must correspond to the project
                        supplied via --project_name (default: None)
  --quac_watch_config   YAML config path specifying QC thresholds for QuaC-
                        Watch. See directory 'configs/quac_watch/' in quac
                        repo for the included config files. (default: None)
  --workflow_config     YAML config path specifying filepath to dependencies
                        of QC tools used in snakemake workflow (default:
                        configs/workflow.yaml)
  --snakemake_cluster_config
                        Cluster config json file. Needed for snakemake to run
                        jobs in cluster. Edit template file
                        'configs/snakemake_cluster_config.json' to suit your
                        SLURM environment. (default: None)
  --outdir              Out directory path (default:
                        data/quac/results/test_project/analysis)
  --tmp_dir             Directory path to store temporary files created by the
                        workflow (default: data/quac/tmp)
  --exome               Flag to run the workflow in exome mode. WARNING:
                        Please provide appropriate configs via
                        --quac_watch_config. (default: False)
  --include_prior_qc    Flag to additionally use prior QC data as input. See
                        documentation for more info. (default: False)
  --allow_sample_renaming
                        Flag to allow sample renaming in MultiQC report. See
                        documentation for more info. (default: False)
  -e , --extra_args     Pass additional custom args to snakemake. Equal symbol
                        is needed for assignment as in this example: -e='--
                        forceall' (default: None)
  -n, --dryrun          Flag to dry-run snakemake. Does not execute anything,
                        and just display what would be done. Equivalent to '--
                        extra_args "-n"' (default: False)

QuaC wrapper options:
  --cli_cluster_config
                        Cluster config json file to run parent workflow job in
                        cluster. Edit template file
                        'configs/cli_cluster_config.json' to suit your SLURM
                        environment. (default: None)
  --log_dir             Directory path where logs (both workflow's and
                        wrapper's) will be stored (default: data/quac/logs)
```

### Useful features

Besides the basic features, wrapper script [`src/run_quac.py`](../src/run_quac.py) offers the following:

- Pass custom snakemake args using option `--extra_args`.
- Dry-run snakemake using flag `--dryrun`. Note that this is same as `--extra_args='-n'`.
- Submit snakemake process to Slurm, instead of running it locally, using `--cli_cluster_config`. 
- Submit jobs triggered by snakemake workflow to Slurm using `--snakemake_cluster_config`.

## Minimal example

Minimal example to run the wrapper script, which in turn will execute the QuaC pipeline on-machine:
(instead of using a SLURM job scheduler on an HPC system for running on a distributed system)

```sh
# First set up dependencies in the environment. 
### Cheaha users can set them up as follows. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

# run CLI/wrapper script
python src/run_quac.py \
      --project_name "PROJECT_DUCK" \
      --projects_path "/path/to/the/projects" \
      --pedigree "path/to/lake/with/ducks_pedigree_file.ped" \
      --quac_watch_config "path/to/quac_watch_config.yaml"
```

## Example usage

Refer to commands used in [system testing](./system_testing.md) for example usage.
