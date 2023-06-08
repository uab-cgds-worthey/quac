#!/usr/bin/env python3

"""
QuaC pipeline runner tool.

Reads user input data, constructs snakemake command to run the pipeline,
and submits them as slurm job or local job.

Run the script with --help flag to see its available options.

"""

import argparse
from pathlib import Path
import uuid
import os.path
import json
import yaml
from slurm.submit_slurm_job import submit_slurm_job


def make_dir(d):
    """
    Ensure directory exists
    """

    Path(d).mkdir(parents=True, exist_ok=True)

    return None


def check_mount_paths_exist(paths):
    """
    Verify the paths to be mounted to Singularity exist
    """

    fail_paths = []
    for path in paths:
        # print(path)
        if not Path(path).exists():
            fail_paths.append(str(path))

    if fail_paths:
        fail_paths = "\n".join(fail_paths)
        raise SystemExit(
            (
                f"ERROR: Following directories that are part of your input were not found: \n{fail_paths}"
                "\n\nNOTE: This was likely caused by missing datasets specified in the workflow config file (supplied via --workflow_config)."
                "\nPlease refer to docs on how to use our script to download the necessary datasets - https://quac.readthedocs.io/en/latest/reqts_configs/#set-up-workflow-config-file"
            )
        )

    return None


def read_workflow_config(workflow_config_fpath):
    """
    Read workflow config file to
    (1) identify paths to be mounted for singularity.
    (2) get slurm partitions.
    """

    with open(workflow_config_fpath) as fh:
        data = yaml.safe_load(fh)

    mount_paths = set()
    datasets = data["datasets"]
    # ref genome
    mount_paths.add(Path(get_full_path(datasets["ref"])).parent)

    # somalier resource files
    for resource in datasets["somalier"]:
        mount_paths.add(Path(get_full_path(datasets["somalier"][resource])).parent)

    # verifyBamID resource files
    for resource in datasets["verifyBamID"]:
        mount_paths.add(Path(get_full_path(datasets["verifyBamID"][resource])).parent)

    return mount_paths


def gather_mount_paths(
    projects_path,
    project_name,
    pedigree_path,
    out_dir,
    log_dir,
    quac_watch_config,
    workflow_config,
):
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

    # QuaC-Watch configfile
    mount_paths.add(quac_watch_config)

    # read paths in workflow config file
    paths_in_wokflow_config = read_workflow_config(workflow_config)
    mount_paths.update(paths_in_wokflow_config)

    # checks paths to be mounted to singularity exist
    check_mount_paths_exist(mount_paths)

    return ",".join([str(x) for x in mount_paths])


def construct_sbatch_command(config_f):
    """
    Reads cluster config file and constructs sbatch command to use in slurm
    """
    
    with open(config_f) as fh:
        data = json.load(fh)
        
        default_args = data["__default__"]
        
        sbatch_cmd = "sbatch "
        for k, v in default_args.items():
            sbatch_cmd += f"--{k} {{cluster.{k}}} "

        sbatch_cmd += "--parsable"
            
    return sbatch_cmd


def create_snakemake_command(args, repo_path, mount_paths):
    """
    Construct snakemake command to run the pipeline
    """

    # slurm profile dir for snakemake to properly handle to cluster job fails
    snakemake_profile_dir = repo_path / "src/slurm/slurm_profile"

    # use absolute path to run it from anywhere
    snakefile_path = repo_path / "workflow" / "Snakefile"

    # directory to use as tmp in singularity container
    # If not exist, singularity will complain
    tmp_dir = args.tmp_dir

    quac_configs = {
        "project_name": args.project_name,
        "projects_path": args.projects_path,
        "ped": args.pedigree,
        "quac_watch_config": args.quac_watch_config,
        "workflow_config": args.workflow_config,
        "unique_id": str(uuid.uuid4()),
        "out_dir": args.outdir,
        "log_dir": args.log_dir,
        "exome": args.exome,
        "include_prior_qc_data": args.include_prior_qc,
        "allow_sample_renaming": args.allow_sample_renaming,
    }
    quac_configs = " ".join([f"{k}='{v}'" for k, v in quac_configs.items()])

    # snakemake command to run
    cmd = [
        "snakemake",
        f"--snakefile '{snakefile_path}'",
        f"--config {quac_configs}",
        f"--restart-times {args.rerun_failed}",
        "--use-singularity",
        f"--singularity-args '--cleanenv --bind {tmp_dir}:/tmp --bind {mount_paths}'",
        f"--profile '{snakemake_profile_dir}'",
    ]

    if args.subtasks_slurm:
        cmd += [
            f"--cluster-config '{args.snakemake_cluster_config}'",
            f"--cluster '{construct_sbatch_command(args.snakemake_cluster_config)}'"
        ]

    # add any user provided extra args for snakemake
    if args.extra_args:
        cmd += [args.extra_args]

    # adds option for dryrun if requested
    if args.dryrun:
        cmd += ["--dryrun"]

    return cmd


def main(args):

    repo_path = Path(get_full_path(__file__)).parents[1]

    # process user's input-output config file and get singularity bind paths
    mount_paths = gather_mount_paths(
        args.projects_path,
        args.project_name,
        args.pedigree,
        args.outdir,
        args.log_dir,
        args.quac_watch_config,
        args.workflow_config,
    )

    # get snakemake command to execute for the pipeline
    snakemake_cmd = create_snakemake_command(args, repo_path, mount_paths)

    # put together pipeline command to be run
    pipeline_cmd = " \\\n\t".join(snakemake_cmd)

    print(
        f'{"#" * 40}\n'
        "Command to run the pipeline:\n"
        "\x1B[31;95m" + pipeline_cmd + "\x1B[0m\n"
        f'{"#" * 40}\n'
    )

    # submit snakemake command as a slurm job
    with open(args.cli_cluster_config) as fh:
        slurm_resources = json.load(fh)

    job_dict = {
        "basename": "quac-",
        "log_dir": args.log_dir,
        "run_locally": False if args.snakemake_slurm else True,
        "resources": slurm_resources,
    }

    submit_slurm_job(pipeline_cmd, job_dict)

    return None


def get_full_path(x):
    full_path = Path(x).resolve()

    return str(full_path)


def is_valid_file(p, arg):
    if not Path(arg).is_file():
        p.error("The file '%s' does not exist!" % arg)
    else:
        return get_full_path(arg)


def is_valid_dir(p, arg):
    if not Path(os.path.expandvars(arg)).is_dir():
        p.error("The directory '%s' does not exist!" % arg)
    else:
        return get_full_path(os.path.expandvars(arg))


def create_dirpath(arg):
    dpath = get_full_path(os.path.expandvars(arg))
    if not Path(dpath).is_dir():
        make_dir(dpath)
        print(f"Created directory: {dpath}")

    return dpath


if __name__ == "__main__":
    PARSER = argparse.ArgumentParser(
        description="Command line interface to QuaC pipeline.",
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
        "--projects_path",
        help="Path where all projects are hosted. Do not include project name here.",
        type=lambda x: is_valid_dir(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--pedigree",
        help="Pedigree filepath. Must correspond to the project supplied via --project_name",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--quac_watch_config",
        help=(
            "YAML config path specifying QC thresholds for QuaC-Watch."
            " See directory 'configs/quac_watch/' in quac repo for the included config files."
        ),
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--workflow_config",
        help="YAML config path specifying filepath to dependencies of tools used in QuaC",
        default="configs/workflow.yaml",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    SMK_CLUSTER_CONFIG_DEFAULT = (
        Path(__file__).absolute().parents[1] / "configs/snakemake_cluster_config.json"
    )
    WORKFLOW.add_argument(
        "--snakemake_cluster_config",
        help="Cluster config json file. Needed for snakemake to run jobs in cluster.",
        default=SMK_CLUSTER_CONFIG_DEFAULT,
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    QUAC_OUTDIR_DEFAULT = "data/quac/results/test_project/analysis"
    WORKFLOW.add_argument(
        "--outdir",
        help="Out directory path",
        default=QUAC_OUTDIR_DEFAULT,
        type=lambda x: create_dirpath(x),
        metavar="",
    )
    TMPDIR_DEFAULT = "data/quac/tmp"
    WORKFLOW.add_argument(
        "--tmp_dir",
        help="Directory path to store temporary files created by the workflow",
        default=TMPDIR_DEFAULT,
        type=lambda x: create_dirpath(x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--exome",
        action="store_true",
        help="Flag to run the workflow in exome mode. WARNING: Please provide appropriate configs via --quac_watch_config.",
    )
    WORKFLOW.add_argument(
        "--include_prior_qc",
        action="store_true",
        help="Flag to additionally use prior QC data as input. See documentation for more info.",
    )
    WORKFLOW.add_argument(
        "--allow_sample_renaming",
        action="store_true",
        help="Flag to allow sample renaming in MultiQC report. See documentation for more info.",
    )
    WORKFLOW.add_argument(
        "--subtasks_slurm",
        action="store_true",
        help="Flag indicating that the main Snakemake process of QuaC should submit subtasks of"
        " the workflow as Slurm jobs instead of running them on the same machine as itself",
    )

    ############ Args for QuaC wrapper tool  ############
    WRAPPER = PARSER.add_argument_group("QuaC wrapper options")

    CLI_CLUSTER_CONFIG_DEFAULT = (
        Path(__file__).absolute().parents[1] / "configs/cli_cluster_config.json"
    )
    WRAPPER.add_argument(
        "--cli_cluster_config",
        help="Cluster config json file to run parent workflow job in cluster",
        default=CLI_CLUSTER_CONFIG_DEFAULT,
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    LOGS_DIR_DEFAULT = f"data/quac/logs"
    WRAPPER.add_argument(
        "--log_dir",
        help="Directory path where logs (both workflow's and wrapper's) will be stored",
        default=LOGS_DIR_DEFAULT,
        type=lambda x: create_dirpath(x),
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
        "--snakemake_slurm",
        action="store_true",
        help="Flag indicating that the main Snakemake process of QuaC should be"
        " submitted to run in a Slurm job instead of executing in the current"
        " environment. Useful for headless execution on Slurm-based HPC systems.",
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

    # Didn't find a argparse friendly solution without having to refactor. Good enough solution
    if not ARGS.quac_watch_config:
        raise SystemExit(
            "Error. Quac-watch config is missing. Please supply using --quac_watch_config."
        )
    if not ARGS.projects_path:
        raise SystemExit(
            "Error. 'Projects path' not provided. Please supply using --projects_path."
        )

    main(ARGS)