"""
Reads multiqc general stats file.
Provides a generic helper function to verify stats based on multiqc's general stats data.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def read_stats(filepath):
    "Reads multiqc general stats file"

    LOGGER.info(f"Reading multiqc general stats file: {filepath}")
    df = pd.read_csv(filepath, sep="\t", index_col="Sample")

    return df


def check_thresholds(multiqc_df, sample_name, tool, config, tool_prefix, outfile):
    """
    Read a tool's overall QC summary for a particular sample using multiqc's general stats data
    and summarize the result.

    Args:
        multiqc_df (df): multiqc general stats dataframe
        sample_name (str): sample name
        tool (str): tool name
        config (dict): Thresholds for QC metrics
        tool_prefix (str): Tool's prefix used by multiqc in their general stats data
        outfile (str): Output filepath

    Returns:
        str: Result stating if sample has passed or failed the tests (pass, fail).
    """

    LOGGER.info(
        f"Analyzing overall '{tool}' QC results for sample '{sample_name}' using multiqc general stats data"
    )

    if sample_name not in multiqc_df.index:
        LOGGER.exception(
            f"Sample '{sample_name}' not present in multiqc's general stats data. Exiting now"
        )
        raise SystemExit(1)

    results_dict = {sample_name: {}}
    pass_fail = set()
    for qc_metric in config:
        if tool == "bcftools_stats" and qc_metric in [
            "perc_snps",
            "perc_indels",
            "heterozygosity_ratio",
        ]:
            total_variants = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_records"]

            if qc_metric == "perc_snps":
                total_snps = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_SNPs"]
                value = ((total_snps / total_variants) * 100).round(3)
            elif qc_metric == "perc_indels":
                total_indels = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_indels"]
                value = ((total_indels / total_variants) * 100).round(3)
            elif qc_metric == "heterozygosity_ratio":
                nonref_homo = multiqc_df.loc[sample_name, f"{tool_prefix}-variations_hom"]
                het = multiqc_df.loc[sample_name, f"{tool_prefix}-variations_het"]
                value = (het / nonref_homo).round(3)

        elif tool == "qualimap" and qc_metric in ["mean_cov:median_cov"]:
            if qc_metric == "mean_cov:median_cov":
                mean_cov = multiqc_df.loc[sample_name, f"{tool_prefix}-mean_coverage"]
                median_cov = multiqc_df.loc[sample_name, f"{tool_prefix}-median_coverage"]
                value = (mean_cov / median_cov).round(3)

        elif tool == "verifybamid" and qc_metric in ["FREEMIX"]:
            if qc_metric == "FREEMIX":
                value = multiqc_df.loc[sample_name, f"{tool_prefix}-{qc_metric}"] * 100
        else:
            value = multiqc_df.loc[sample_name, f"{tool_prefix}-{qc_metric}"]

        minimum = config[qc_metric]["min"]
        maximum = config[qc_metric]["max"]

        result = present_within_range(value, minimum, maximum)
        results_dict[sample_name][f"{qc_metric}_val"] = float(value)
        results_dict[sample_name][qc_metric] = "pass" if result else "fail"
        pass_fail.add(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_fail) else "fail"

    return qc_check_status
