# How to run QuaC pipeline

After [proper installation and configuration](./installation_configuration.md), QuaC pipeline can be run using the
wrapper/CLI (command line interface) tool `src/run_quac.py`.

## Command line interface

```sh
$ python src/run_quac.py -h
usage: run_quac.py [-h] --sample_config SAMPLE_CONFIG --pedigree PEDIGREE
                   --quac_watch_config QUAC_WATCH_CONFIG [--workflow_config]
                   [--snakemake_cluster_config] [--outdir] [--tmp_dir]
                   [--exome] [--include_prior_qc] [--allow_sample_renaming]
                   [-e] [-n] [--cli_cluster_config] [--log_dir]

Command line interface to QuaC pipeline.

optional arguments:
  -h, --help            show this help message and exit

QuaC snakemake workflow options:
  --sample_config SAMPLE_CONFIG
                        Sample config file in TSV format. Provides sample name
                        and necessary input filepaths (bam, vcf, etc.).
                        Required. (default: None)
  --pedigree PEDIGREE   Pedigree filepath. Must correspond to samples
                        mentioned in configfile via --sample_config. Required.
                        (default: None)
  --quac_watch_config QUAC_WATCH_CONFIG
                        YAML config path specifying QC thresholds for QuaC-
                        Watch. See directory 'configs/quac_watch/' in quac
                        repo for the included config files. Required.
                        (default: None)
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

## Example usage

Refer to commands used in [system testing](./system_testing.md) for example usage.
