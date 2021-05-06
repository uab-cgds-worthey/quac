"""
Functions to help with QC checkup tool
"""

from pathlib import Path
import pandas as pd
import yaml
import logging.config


def is_valid_file(p, arg):
    if not Path(arg).is_file():
        p.error("The file '%s' does not exist!" % arg)
    else:
        return arg


def get_configs(filepath):
    "read configs"

    LOGGER.info(f"Reading QC config file: {filepath}")
    with open(filepath) as file_handle:
        config_dict = yaml.safe_load(file_handle)

    return config_dict


def present_within_range(num, minimum, maximum):
    """
    checks if a number is present within a range.
    Both or either of minimum or maximum limits are required.
    """

    # both minimum and maximum given
    if minimum and maximum:
        if minimum <= num <= maximum:
            status = True
        else:
            status = False

    # only minimum given
    if minimum and not maximum:
        if num >= minimum:
            status = True
        else:
            status = False

    # only maximum given
    if maximum and not minimum:
        if num <= maximum:
            status = True
        else:
            status = False

    if not minimum and not maximum:
        LOGGER.exception("Both or either of minimum or maximum limits need to be provided")
        raise SystemExit(1)

    return status


def write_to_yaml_file(results_dict, filepath):
    "writes dictionary to YAML file, in multiqc custom data format"

    # multiqc required 'data' key. Note that custom configs necessary to accepted by
    # multiqc are separately defined in a multiqc config file
    out_dict = {"data": results_dict}

    with open(filepath, "w") as f_handle:
        yaml.dump(out_dict, f_handle, default_flow_style=False, sort_keys=False)

    LOGGER.info(f"Saved results to file: {filepath}")

    return None


def qc_logger(module_name):
    """
    Sets up logging. Also returns repo's root path.

    Arguments:
        module_name {str} -- module name
    """

    config_f = "configs/qc_checkup/logging.ini"
    logging.config.fileConfig(config_f, disable_existing_loggers=False)
    qc_logger = logging.getLogger(module_name)

    return qc_logger


# setup logging
LOGGER = qc_logger(__name__)
