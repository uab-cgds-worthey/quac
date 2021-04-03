"""
Read a tool's overall QC summary for a particular sample using multiqc's general stats data
and summarize the result.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def analyze(multiqc_df, sample_name, tool, config, tool_prefix, outfile):

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
        if tool == "bcftools_stats":
            total_variants = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_records"]
            if qc_metric == "perc_snps":
                total_snps = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_SNPs"]
                value = ((total_snps / total_variants) * 100).round(3)
            elif qc_metric == "perc_indels":
                total_indels = multiqc_df.loc[sample_name, f"{tool_prefix}-number_of_indels"]
                value = ((total_indels / total_variants) * 100).round(3)

        elif tool == "qualimap":
            if qc_metric == "mean_cov:median_cov":
                mean_cov = multiqc_df.loc[sample_name, f"{tool_prefix}-mean_coverage"]
                median_cov = multiqc_df.loc[sample_name, f"{tool_prefix}-median_coverage"]
                value = (mean_cov / median_cov).round(3)

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
