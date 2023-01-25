# Command line interface

After activating the conda environment, QuaC pipeline can be run using the wrapper/CLI script src/run_quac.py. Here are all the options available:

```sh
$ python src/run_quac.py -h
usage: run_quac.py [-h] [--project_name] [--projects_path] [--pedigree]
                   [--quac_watch_config] [--workflow_config] [--outdir]
                   [--tmp_dir] [--exome] [--include_prior_qc]
                   [--allow_sample_renaming] [--cluster_config] [--log_dir]
                   [-e] [-n] [-l] [--rerun_failed] [--slurm_partition]

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
                        Watch (default:
                        configs/quac_watch/wgs_quac_watch_config.yaml)
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

QuaC wrapper options:
  --cluster_config      Cluster config json file. Needed for snakemake to run
                        jobs in cluster. 
                        (default: working_dir/quac/configs/cluster_config.json)
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


## Useful features

Besides the basic features, wrapper script [`src/run_quac.py`](./src/run_quac.py) offers the following:

- Pass custom snakemake args using option `--extra_args`.
- Dry-run snakemake using flag `--dryrun`. Note that this is same as `--extra_args='-n'`.
- Override cluster config file passed to snakemake using `--cluster_config`.
- Run snakemake locally, instead of submitting it to Slurm, using `--run_locally`. Note that jobs triggered by snakemake
  workflow will still be submitted to Slurm.
- Reruns failed jobs once again by default. This may be modified using `--rerun_failed`.
- Override slurm partition used via `--slurm_partition`.

