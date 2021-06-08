"""
Analyze chromosome-level variant frquency using bcftools-index file and summarize the result.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def read_file(f):
    "Reads bcftools index file and calculates %variant-freq per contig"

    df = pd.read_csv(f, sep="\t", names=["contig", "length", "variant_count"], index_col="contig")
    df["var_freq"] = (df["variant_count"] / df["length"]) * 100

    return df


def stat_by_chromosome(bcftools_index_f, sample_name, variant_freq_config, outfile):
    """
    Analyzes chromosome-level variant frquency using bcftools-index file and summarizes the result.

    Args:
        bcftools_index_f (str): Bcftools-index file
        sample_name (str): sample name
        variant_freq_config (dict): Thresholds for QC metrics
        outfile (str): Output filepath

    Returns:
        str: Result stating if sample has passed or failed the tests (pass, fail).
    """

    LOGGER.info(
        f"Analyzing chromosome-level coverage QC using qualimap report file: {bcftools_index_f}"
    )
    LOGGER.info(f"Sample name supplied by user: {sample_name}")

    df = read_file(bcftools_index_f)

    chrom_list = [f"chr{x}" for x in list(range(1, 23)) + ["X", "Y"]]
    results_dict = {sample_name: {}}
    pass_or_fail = set()
    for chrom in chrom_list:
        minimum = variant_freq_config[chrom]["min"]
        maximum = variant_freq_config[chrom]["max"]

        if chrom in df.index:
            variant_freq = df.loc[chrom, "var_freq"]
            result = present_within_range(variant_freq, minimum, maximum)
            results_dict[sample_name][f"{chrom}_val"] = float(f"{variant_freq:.6f}")
        else:
            result = False
            results_dict[sample_name][f"{chrom}_val"] = 0

        results_dict[sample_name][chrom] = "pass" if result else "fail"
        pass_or_fail.add(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_or_fail) else "fail"

    return qc_check_status
