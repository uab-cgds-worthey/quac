# How to run QuaC pipeline

After [fulfilling the necessary requirements and setting up the workflow configs](./reqts_configs.md) and [activating the conda environment](./installation.md), QuaC pipeline can
be run using the wrapper/CLI (command line interface) tool `src/run_quac.py`


## Command line interface

```sh
$ python src/run_quac.py -h
usage: run_quac.py [-h] [--project_name] [--projects_path] [--pedigree]
                   [--quac_watch_config] [--workflow_config] [--outdir]
                   [--tmp_dir] [--exome] [--include_prior_qc]
                   [--allow_sample_renaming] [--subtasks_slurm]
                   [--cluster_config] [--log_dir] [-e] [-n]
                   [--snakemake_slurm] [--rerun_failed] [--slurm_partition]

Command line interface to QuaC pipeline.

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
                        Watch. See directory 'configs/quac_watch/' in quac
                        repo for the included config files. (default: None)
  --workflow_config     YAML config path specifying filepath to dependencies
                        of tools used in QuaC (default: configs/workflow.yaml)
  --outdir              Out directory path (default:
                        $USER_SCRATCH/tmp/quac/results/test_project/analysis)
  --tmp_dir             Directory path to store temporary files created by the
                        workflow (default: $USER_SCRATCH/tmp/quac/tmp)
  --exome               Flag to run the workflow in exome mode. WARNING:
                        Please provide appropriate configs via
                        --quac_watch_config. (default: False)
  --include_prior_qc    Flag to additionally use prior QC data as input. See
                        documentation for more info. (default: False)
  --allow_sample_renaming
                        Flag to allow sample renaming in MultiQC report. See
                        documentation for more info. (default: False)
  --subtasks_slurm      Flag indicating that the main Snakemake process of
                        QuaC should submit subtasks of the workflow as Slurm
                        jobs instead of running them on the same machine as
                        itself (default: False)

QuaC wrapper options:
  --cluster_config      Cluster config json file. Needed for snakemake to run
                        jobs in cluster. (default: quac/configs/cluster_config.json)
  --log_dir             Directory path where logs (both workflow's and
                        wrapper's) will be stored (default:
                        $USER_SCRATCH/tmp/quac/logs)
  -e , --extra_args     Pass additional custom args to snakemake. Equal symbol
                        is needed for assignment as in this example: -e='--
                        forceall' (default: None)
  -n, --dryrun          Flag to dry-run snakemake. Does not execute anything,
                        and just display what would be done. Equivalent to '--
                        extra_args "-n"' (default: False)
  --snakemake_slurm     Flag indicating that the main Snakemake process of
                        QuaC should be submitted to run in a Slurm job instead
                        of executing in the current environment. Useful for
                        headless execution on Slurm-based HPC systems.
                        (default: False)
  --rerun_failed        Number of times snakemake restarts failed jobs. This
                        may be set to >0 to avoid pipeline failing due to job
                        fails due to random SLURM issues (default: 1)
  --slurm_partition     Request a specific partition for the slurm resource
                        allocation to run snakemake. See 'slurm_partitions'
                        supplied via workflow_config for available partitions
                        (default: short)
```

### Useful features

Besides the basic features, wrapper script [`src/run_quac.py`](../src/run_quac.py) offers the following:

- Pass custom snakemake args using option `--extra_args`.
- Dry-run snakemake using flag `--dryrun`. Note that this is same as `--extra_args='-n'`.
- Override cluster config file passed to snakemake using `--cluster_config`.
- Submit snakemake process to Slurm, instead of running it locally, using `--snakemake_slurm`. 
- Override slurm partition used for the snakemake procees via `--slurm_partition`.
- Submit jobs triggered by snakemake workflow to Slurm using `--subtasks_slurm`.
- Reruns failed jobs once again by default. This may be modified using `--rerun_failed`.

## Minimal example

Minimal example to run the wrapper script, which in turn will execute the QuaC pipeline:

```sh
# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

# run CLI/wrapper script
python src/run_quac.py \
      --project_name PROJECT_DUCK \
      --pedigree "path/to/lake/with/pedigree_file.ped"
```

## Example usage

[TODO] Modify examples based on new PR under review

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
