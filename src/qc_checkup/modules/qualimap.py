"""
1. Read overall qualimap QC summary for a particular sample using multiqc's general stats data
and summarize the result.
2. Analyze chromosome-level coverage QC using qualimap report file and summarize the result.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


# def overall_stats(multiqc_df, sample_name, qualimap_config, outfile):
#     """
#     Reads overall qualimap QC summary for a particular sample using multiqc's general stats data
#     and summarizes the result.
#     """

#     LOGGER.info(
#         f"Analyzing overall qualimap results for sample '{sample_name}' using multiqc general stats data"
#     )

#     if sample_name not in multiqc_df.index:
#         LOGGER.exception(
#             f"Sample '{sample_name}' not present in multiqc's general stats data. Exiting now"
#         )
#         raise SystemExit(1)

#     qualimap_prefix = "QualiMap_mqc-generalstats-qualimap"
#     if pd.isnull(multiqc_df.loc[sample_name, f"{qualimap_prefix}-avg_gc"]):
#         LOGGER.exception(
#             f"Qualimap data not available for '{sample_name}' in multiqc's general stats data. Exiting now"
#         )
#         raise SystemExit(1)

#     results_dict = {sample_name: {}}
#     pass_fail = set()
#     for qc_metric in qualimap_config:
#         if qc_metric == "mean_cov:median_cov":
#             mean_cov = multiqc_df.loc[sample_name, f"{qualimap_prefix}-mean_coverage"]
#             median_cov = multiqc_df.loc[sample_name, f"{qualimap_prefix}-median_coverage"]
#             value = (mean_cov / median_cov).round(3)
#         else:
#             value = multiqc_df.loc[sample_name, f"{qualimap_prefix}-{qc_metric}"]

#         minimum = qualimap_config[qc_metric]["min"]
#         maximum = qualimap_config[qc_metric]["max"]

#         result = present_within_range(value, minimum, maximum)
#         results_dict[sample_name][f"{qc_metric}_val"] = float(value)
#         results_dict[sample_name][qc_metric] = "pass" if result else "fail"
#         pass_fail.add(result)

#     # write results to file
#     write_to_yaml_file(results_dict, outfile)

#     # summarize results to one term
#     qc_check_status = "pass" if all(pass_fail) else "fail"

#     return qc_check_status


def stat_by_chromosome(qualimap_f, sample_name, qualimap_config, outfile):
    """
    Analyzes chromosome-level coverage QC using qualimap report file
    and summarize the result.
    """

    LOGGER.info(f"Analyzing chromosome-level coverage QC using qualimap report file: {qualimap_f}")
    LOGGER.info(f"Sample name supplied by user: {sample_name}")

    chrom_list = [f"chr{x}" for x in list(range(1, 23)) + ["X", "Y"]]
    minimum = qualimap_config["mean_coverage"]["min"]
    maximum = qualimap_config["mean_coverage"]["max"]

    results_dict = {sample_name: {}}
    pass_fail = []
    with open(qualimap_f, "r") as f_handle:
        parse_status = False
        for line in f_handle:
            line = line.strip()

            if line.startswith(">>>>>>> Coverage per contig"):
                parse_status = True
                continue

            if parse_status:
                line_list = line.split("\t")
                chrom = line_list[0]
                if chrom in chrom_list:
                    mean_cov = float(line_list[3])

                    # for chromosomes X and Y, min coverage required is half of that of other chromosomes
                    if chrom in ["chrX", "chrY"]:
                        result = present_within_range(mean_cov, minimum / 2, maximum)
                    else:
                        result = present_within_range(mean_cov, minimum, maximum)

                    results_dict[sample_name][chrom] = float(f"{mean_cov:.1f}")
                    pass_fail.append(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one status. A bit arbitrary atm.
    # Could use improvement in logic. Using sample's gender could help.
    if sum(pass_fail) <= 20:
        qc_check_status = "fail"
    elif sum(pass_fail) <= 21:
        qc_check_status = "warn"
    else:
        qc_check_status = "pass"

    return qc_check_status
