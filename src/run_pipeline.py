#!/usr/bin/env python3

"""
Reads user input data, constructs snakemake command to run the pipeline
along with their required modules, and submits them as slurm job.

Run the script with --help flag to see its available options.

Example usage:
IO_CONFIG=".test/configs/user_io_config.yaml"
src/run_pipeline.py --io_config $IO_CONFIG

"""

import argparse
from pathlib import Path
import os.path
import yaml
from utility_cgds.cgds.pipeline.src.submit_slurm_job import submit_slurm_job


def create_snakemake_command(args):
    """
    Construct snakemake command to run the pipeline
    """

    # slurm profile dir for snakemake to properly handle to cluster job fails
    repo_path = Path(__file__).absolute().parents[1]
    snakemake_profile_dir = (
        repo_path / "configs/snakemake_slurm_profile//{{cookiecutter.profile_name}}/"
    )

    # use absolute path to run it from anywhere
    snakefile_path = repo_path / "workflow" / "Snakefile"

    # snakemake command to run
    cmd = [
        "snakemake",
        f"--snakefile {snakefile_path}",
        f"--config modules='{args.modules}' project_name={args.project_name} ped={args.pedigree} out_dir={args.outdir} log_dir={args.log_dir}",
        f"--restart-times {args.rerun_failed}",
        "--use-conda",
        f"--profile '{snakemake_profile_dir}'",
        f"--cluster-config '{args.cluster_config}'",
        "--cluster 'sbatch --ntasks {cluster.ntasks} --partition {cluster.partition}"
        " --cpus-per-task {cluster.cpus-per-task} --mem {cluster.mem}"
        " --output {cluster.output} --parsable'",
    ]

    # add any user provided extra args for snakemake
    if args.extra_args:
        cmd += [args.extra_args]

    # adds option for dryrun if requested
    if args.dryrun:
        cmd += ["--dryrun"]

    return cmd


def main(args):

    # get snakemake command to execute for the pipeline
    snakemake_cmd = create_snakemake_command(args)

    # put together pipeline command to be run
    anaconda_module = "Anaconda3/2020.02"
    snakemake_module = "snakemake/5.9.1-foss-2018b-Python-3.6.6"
    pipeline_cmd = "\n".join(
        [
            f"module reset",
            f"module load {anaconda_module}  {snakemake_module}",
            " \\\n\t".join(snakemake_cmd),
        ]
    )

    print(
        f'{"#" * 40}\n'
        # f"Input-output configs provided by user: '{args.io_config}'\n"
        f"Cluster configs                      : '{args.cluster_config}'\n\n"
        "Command to run the pipeline:\n"
        "\x1B[31;95m" + pipeline_cmd + "\x1B[0m\n"
        f'{"#" * 40}\n'
    )

    # submit snakemake command as a slurm job
    # Choose resources depending on if manta_execute rule will be run
    # as localrule in snakemake or not.
    slurm_resources = {
        "partition": "short",  # express(max 2 hrs), short(max 12 hrs), medium(max 50 hrs), long(max 150 hrs)
        "ntasks": "1",
        "time": "12:00:00",
        "cpus-per-task": "1",
        "mem": "8G",
    }

    job_dict = {
        "basename": "quac-",
        "log_dir": args.log_dir,
        "run_locally": args.run_locally,
        "resources": slurm_resources,
    }

    submit_slurm_job(pipeline_cmd, job_dict)

    return None


def is_valid_file(p, arg):
    if not Path(arg).is_file():
        p.error("The file '%s' does not exist!" % arg)
    else:
        return arg


def is_valid_dir(p, arg):
    if not Path(os.path.expandvars(arg)).is_dir():
        p.error("The directory '%s' does not exist!" % arg)
    else:
        return os.path.expandvars(arg)


if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(
        description="A wrapper for QuaC pipeline.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    ############ Args for QuaC workflow  ############
    WORKFLOW = PARSER.add_argument_group("QuaC workflow options")

    WORKFLOW.add_argument(
        "--project_name",
        help="Project name",
        metavar="",
    )
    WORKFLOW.add_argument(
        "--pedigree",
        help="Pedigree filepath. Must be specific for the project supplied via --project_name",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    QUAC_OUTDIR_DEFAULT = "$USER_SCRATCH/tmp/quac/results"
    WORKFLOW.add_argument(
        "--outdir",
        help="Out directory path",
        default=QUAC_OUTDIR_DEFAULT,
        type=lambda x: is_valid_dir(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "-m",
        "--modules",
        help="Runs only these user-specified modules(s). If >1, use comma as delimiter. \
            Useful for development.",
        default="all",
        metavar="",
    )

    ############ Args for QuaC wrapper tool  ############
    WRAPPER = PARSER.add_argument_group("QuaC wrapper options")

    CLUSTER_CONFIG_DEFAULT = Path(__file__).absolute().parents[1] / "configs/cluster_config.json"
    WRAPPER.add_argument(
        "--cluster_config",
        help="Cluster config json file. Needed for snakemake to run jobs in cluster.",
        default=CLUSTER_CONFIG_DEFAULT,
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    LOGS_DIR_DEFAULT = f"{QUAC_OUTDIR_DEFAULT}/../logs"
    WRAPPER.add_argument(
        "--log_dir",
        help="Directory path where logs (both workflow and wrapper) will be stored",
        default=LOGS_DIR_DEFAULT,
        type=lambda x: is_valid_dir(PARSER, x),
        metavar="",
    )
    WRAPPER.add_argument(
        "-e",
        "--extra_args",
        help="Pass additional custom args to snakemake. Equal symbol is needed "
        "for assignment as in this example: -e='--forceall'",
        metavar="",
    )
    WRAPPER.add_argument(
        "-n",
        "--dryrun",
        action="store_true",
        help="Flag to dry-run snakemake. Does not execute anything, and "
        "just display what would be done. Equivalent to '--extra_args \"-n\"'",
    )
    WRAPPER.add_argument(
        "-l",
        "--run_locally",
        action="store_true",
        help="Flag to run the snakemake locally and not as a Slurm job. "
        "Useful for testing purposes.",
    )
    RERUN_FAILED_DEFAULT = 1
    WRAPPER.add_argument(
        "--rerun_failed",
        help=f"Number of times snakemake restarts failed jobs. This may be set to >0 "
        "to avoid pipeline failing due to job fails due to random SLURM issues",
        default=RERUN_FAILED_DEFAULT,
        metavar="",
    )

    ARGS = PARSER.parse_args()

    main(ARGS)
