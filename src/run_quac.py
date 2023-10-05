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
from shutil import which
import json
import yaml
from singularity_status import test_singularity
from slurm.submit_slurm_job import submit_slurm_job
from read_sample_config import read_sample_config


def make_dir(d):
    """
    Ensure directory exists
    """

    Path(d).mkdir(parents=True, exist_ok=True)

    return None


def get_tool_path(tool):
    "return tool path in user's system"

    tool_path = which(tool)

    return tool_path


def check_sample_configs(fpath, exome_mode, include_prior_qc, allow_sample_renaming):
    """
    reads from sample configfile and verifies necessary column names exist
    """

    samples_dict, header = read_sample_config(fpath)

    if exome_mode:
        if "capture_bed" not in header:
            print(
                f"ERROR: Flag --exome supplied but required column 'capture_bed' is missing in sample configfile '{fpath}'"
            )
            raise SystemExit(1)

        for sample in samples_dict:
            if not samples_dict[sample]["capture_bed"].endswith(".bed"):
                print(
                    f"ERROR: Capture bed filename is required to end with '.bed' extension: '{samples_dict[sample]['capture_bed']}'"
                )
                raise SystemExit(1)

    # TODO
    if include_prior_qc and "TODO" not in header:
        pass

    # TODO
    if allow_sample_renaming and "TODO" not in header:
        pass

    return samples_dict


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
                "\n\nNOTE: This was likely caused by missing datasets specified in the workflow config file"
                "(supplied via --workflow_config)."
                "\nPlease refer to docs on how to use our script to download the necessary datasets -"
                " https://quac.readthedocs.io/en/stable/installation_configuration/#configuration"
            )
        )

    return None


def read_workflow_config(workflow_config_fpath):
    """
    Read workflow config file to
    identify paths to be mounted for singularity.
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
    sample_config_f,
    samples_config_dict,
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

    # sample_config
    mount_paths.add(Path(sample_config_f).parent)

    # input filepaths from sample config
    for sample_val in samples_config_dict.values():
        for val_fpath in sample_val.values():
            mount_paths.add(Path(val_fpath).parent)

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
        "sample_config": args.sample_config,
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
        "--use-singularity",
        f"--singularity-args '--cleanenv --bind {tmp_dir}:/tmp --bind {mount_paths}'",
        f"--profile '{snakemake_profile_dir}'",
    ]

    if args.snakemake_cluster_config:
        cmd += [
            f"--cluster-config '{args.snakemake_cluster_config}'",
            f"--cluster '{construct_sbatch_command(args.snakemake_cluster_config)}'",
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

    # check if dependencies exist
    for dep_tool in ["singularity", "snakemake"]:
        if get_tool_path(dep_tool) is None:
            print(
                f"ERROR: Tool '{dep_tool}' is required to run QuaC but not found in your environment."
            )
            raise SystemExit(1)

    if args.cli_cluster_config or args.snakemake_cluster_config:
        if get_tool_path("sbatch") is None:
            print(
                "ERROR: '--cli_cluster_config' and/or `snakemake_cluster_config` was supplied to utilize SLURM,"
                " but SLURM's 'sbatch' tool was not found in your environment."
            )
            raise SystemExit(1)

    # check singularity works properly in user's machine
    test_singularity()

    # read sample configfile and verify necessary columns exist
    samples_config_dict = check_sample_configs(
        args.sample_config, args.exome, args.include_prior_qc, args.allow_sample_renaming
    )

    # process user's input-output config file and get singularity bind paths
    mount_paths = gather_mount_paths(
        args.sample_config,
        samples_config_dict,
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
    slurm_resources = {}
    if args.cli_cluster_config:

        with open(args.cli_cluster_config) as fh:
            slurm_resources = json.load(fh)

    job_dict = {
        "basename": "quac-",
        "log_dir": args.log_dir,
        "run_locally": False if args.cli_cluster_config else True,
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
    WORKFLOW = PARSER.add_argument_group("QuaC snakemake workflow options")

    WORKFLOW.add_argument(
        "--sample_config",
        help="Sample config file in TSV format. Provides sample name and necessary input filepaths (bam, vcf, etc.). Required.",
        type=lambda x: is_valid_file(PARSER, x),
        required=True,
    )
    WORKFLOW.add_argument(
        "--pedigree",
        help="Pedigree filepath. Must correspond to samples mentioned in configfile via --sample_config. Required.",
        type=lambda x: is_valid_file(PARSER, x),
        required=True,
    )
    WORKFLOW.add_argument(
        "--quac_watch_config",
        help=(
            "YAML config path specifying QC thresholds for QuaC-Watch."
            " See directory 'configs/quac_watch/' in quac repo for the included config files. Required."
        ),
        type=lambda x: is_valid_file(PARSER, x),
        required=True,
    )
    WORKFLOW.add_argument(
        "--workflow_config",
        help="YAML config path specifying filepath to dependencies of QC tools used in snakemake workflow",
        default="configs/workflow.yaml",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )
    WORKFLOW.add_argument(
        "--snakemake_cluster_config",
        help="Cluster config json file. Needed for snakemake to run jobs in cluster."
        " Edit template file 'configs/snakemake_cluster_config.json' to suit your SLURM environment.",
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
        "-e",
        "--extra_args",
        help="Pass additional custom args to snakemake. Equal symbol is needed "
        "for assignment as in this example: -e='--forceall'",
        metavar="",
    )
    WORKFLOW.add_argument(
        "-n",
        "--dryrun",
        action="store_true",
        help="Flag to dry-run snakemake. Does not execute anything, and "
        "just display what would be done. Equivalent to '--extra_args \"-n\"'",
    )

    ############ Args for QuaC wrapper tool  ############
    WRAPPER = PARSER.add_argument_group("QuaC wrapper options")

    WRAPPER.add_argument(
        "--cli_cluster_config",
        help="Cluster config json file to run parent workflow job in cluster."
        " Edit template file 'configs/cli_cluster_config.json' to suit your SLURM environment.",
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

    ARGS = PARSER.parse_args()

    # Didn't find a argparse friendly solution without having to refactor. Good enough solution
    if not ARGS.quac_watch_config:
        raise SystemExit(
            "Error. Quac-watch config is missing. Please supply using --quac_watch_config."
        )

    main(ARGS)
