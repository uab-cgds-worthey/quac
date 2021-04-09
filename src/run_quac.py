#!/usr/bin/env python3

"""
QuaC pipeline runner tool.

Reads user input data, constructs snakemake command to run the pipeline,
and submits them as slurm job.

Run the script with --help flag to see its available options.

Example usage:
# First create environment as described in documentation
python src/run_quac.py --project_name CF_CFF_PFarrell --pedigree data/raw/ped/CF_CFF_PFarrell.ped
python src/run_quac.py --project_name HCC --pedigree data/raw/ped/HCC.ped --exome
python src/run_quac.py --project_name UnusualCancers_CMGalluzi --projects_path /data/project/sloss/cgds_path_cmgalluzzi/ \
        --pedigree data/raw/ped/UnusualCancers_CMGalluzi.ped --exome
"""

import argparse
from pathlib import Path
import os.path
import yaml
from utility_cgds.cgds.pipeline.src.submit_slurm_job import submit_slurm_job


def make_dir(d):
    """
    Ensure directory exists
    """

    Path(d).mkdir(parents=True, exist_ok=True)

    return None


def read_workflow_config(repo_path):
    """
    Read workflow config file and identify paths to be mounted for singularity
    """

    workflow_config_fpath = repo_path / "configs/workflow.yaml"
    with open(workflow_config_fpath) as fh:
        data = yaml.safe_load(fh)

    mount_paths = set()

    # ref genome
    mount_paths.add(Path(data["ref"]).parent)

    # somalier resource files
    for resource in data["somalier"]:
        mount_paths.add(Path(data["somalier"][resource]).parent)

    # verifyBamID resource files
    for resource in data["verifyBamID"]:
        mount_paths.add(Path(data["verifyBamID"][resource]).parent)

    return mount_paths


def gather_mount_paths(projects_path, project_name, pedigree_path, out_dir, log_dir, repo_path):
    """
    Returns paths that need to be mounted to singularity
    """

    mount_paths = set()

    # project path
    project_path = Path(projects_path) / project_name / "analysis"
    make_dir(project_path)
    mount_paths.add(project_path)

    # pedigree filepath
    mount_paths.add(Path(pedigree_path).parent)

    # output dirpath
    make_dir(out_dir)
    mount_paths.add(out_dir)

    # logs dirpath
    mount_paths.add(log_dir)

    # read paths in workflow config file
    mount_paths.update(read_workflow_config(repo_path))

    return ",".join([str(x) for x in mount_paths])


def create_snakemake_command(args, repo_path, mount_paths):
    """
    Construct snakemake command to run the pipeline
    """

    # slurm profile dir for snakemake to properly handle to cluster job fails
    snakemake_profile_dir = (
        repo_path / "configs/snakemake_slurm_profile//{{cookiecutter.profile_name}}/"
    )

    # use absolute path to run it from anywhere
    snakefile_path = repo_path / "workflow" / "Snakefile"

    # directory to use as tmp in singularity container
    # If not exist, singularity will complain
    tmp_dir = os.path.expandvars("$USER_SCRATCH/tmp/quac")
    make_dir(tmp_dir)

    quac_configs = {
        "project_name": args.project_name,
        "projects_path": args.projects_path,
        "ped": args.pedigree,
        "out_dir": args.outdir,
        "log_dir": args.log_dir,
        "exome": args.exome,
    }
    quac_configs = " ".join([f"{k}='{v}'" for k, v in quac_configs.items()])

    # snakemake command to run
    cmd = [
        "snakemake",
        f"--snakefile '{snakefile_path}'",
        "--wms-monitor http://10.111.161.152/panoptes",
        f"--config {quac_configs}",
        f"--restart-times {args.rerun_failed}",
        "--use-conda",
        "--use-singularity",
        f"--singularity-args '--bind {tmp_dir}:/tmp --bind {mount_paths}'",
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

    repo_path = Path(__file__).absolute().parents[1]

    # process user's input-output config file and get singularity bind paths
    mount_paths = gather_mount_paths(
        args.projects_path, args.project_name, args.pedigree, args.outdir, args.log_dir, repo_path
    )

    # get snakemake command to execute for the pipeline
    snakemake_cmd = create_snakemake_command(args, repo_path, mount_paths)

    # put together pipeline command to be run
    singularity_module = "Singularity/3.5.2-GCC-5.4.0-2.26"
    pipeline_cmd = "\n".join(
        [
            f"module load {singularity_module}",
            " \\\n\t".join(snakemake_cmd),
        ]
    )

    print(
        f'{"#" * 40}\n'
        "Command to run the pipeline:\n"
        "\x1B[31;95m" + pipeline_cmd + "\x1B[0m\n"
        f'{"#" * 40}\n'
    )

    # submit snakemake command as a slurm job
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
        description="Wrapper tool for QuaC pipeline.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    ############ Args for QuaC workflow  ############
    WORKFLOW = PARSER.add_argument_group("QuaC workflow options")

    WORKFLOW.add_argument(
        "--project_name",
        help="Project name",
        metavar="",
    )

    PROJECT_PATH_DEFAULT = "/data/project/worthey_lab/projects/"
    WORKFLOW.add_argument(
        "--projects_path",
        help="Path where all projects are hosted. Don't include project name here.",
        default=PROJECT_PATH_DEFAULT,
        type=lambda x: is_valid_dir(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--pedigree",
        help="Pedigree filepath. Must correspond to the project supplied via --project_name",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    QUAC_OUTDIR_DEFAULT = "$USER_SCRATCH/tmp/quac/results/test_project/analysis"
    WORKFLOW.add_argument(
        "--outdir",
        help="Out directory path",
        default=QUAC_OUTDIR_DEFAULT,
        type=lambda x: is_valid_dir(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--exome",
        action="store_true",
        help="Flag to run in exome mode",
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

    LOGS_DIR_DEFAULT = f"$USER_SCRATCH/tmp/quac/logs"
    WRAPPER.add_argument(
        "--log_dir",
        help="Directory path where logs (both workflow's and wrapper's) will be stored",
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
    RERUN_FAILED_DEFAULT = 0
    WRAPPER.add_argument(
        "--rerun_failed",
        help=f"Number of times snakemake restarts failed jobs. This may be set to >0 "
        "to avoid pipeline failing due to job fails due to random SLURM issues",
        default=RERUN_FAILED_DEFAULT,
        metavar="",
    )

    ARGS = PARSER.parse_args()

    main(ARGS)
