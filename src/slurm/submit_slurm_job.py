#!/usr/bin/env python3

"""
Submit a job to slurm using slurmpy
"""

import datetime
from slurmpy import slurmpy


def submit_slurm_job(job_cmd, job_dict):
    """
    Submit job command to slurm using slurmpy

    Arguments:
        job_cmd (str) -- Job's complete command
        job_dict (dict) -- Dictionary containing necessary job info
                    (resources, basename, etc) to pass to slurmpy.
                    Necessary keys: basename, log_dir, resources, run_locally
                    Optional keys: use_bash_strict, env_var_dict

    Returns:
        slurm job ID
    """

    # basename and stuff needed for slurm job name.
    # This will also be used for job script and log file names.
    job_basename = job_dict['basename']
    log_dir = job_dict['log_dir']
    date_time = datetime.datetime.now().isoformat().replace(':', '.')
    job_name = f"{job_basename}{date_time}"
    bash_strict = True if 'use_bash_strict' not in job_dict else job_dict['use_bash_strict']

    print(f'Slurm job name   : "{job_name}"')
    print(f'Slurm job script : "{log_dir}/{job_name}.sh"')

    # set up the slurm job to submit
    slurm_job = slurmpy.Slurm(name=job_basename,
                              slurm_kwargs=job_dict['resources'],
                              scripts_dir=log_dir,
                              log_dir=log_dir,
                              date_in_name=False,
                              bash_strict=bash_strict
                              )

    params_dict = {
        "command": job_cmd,
        "name_addition": date_time
    }

    # check if any environment variables need to be set in the job script
    if "env_var_dict" in job_dict.keys():
        params_dict["cmd_kwargs"] = job_dict["env_var_dict"]

    # check if requested to run as a local job instead of slurm job. Useful for testing.
    if job_dict['run_locally']:
        params_dict["_cmd"] = "bash"

    # submit the slurm job
    job_id = slurm_job.run(**params_dict)

    return job_id
