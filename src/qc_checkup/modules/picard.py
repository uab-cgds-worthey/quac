import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def check_thresholds(results_dict, pass_fail, report_file, config):

    LOGGER.info(f"Reading multiqc's Picard-module report file: {report_file}")

    df = pd.read_csv(report_file, sep="\t", index_col="Sample")

    for sample_name, row in df.iterrows():
        LOGGER.info(f"Working on sample: {sample_name}")

        if sample_name not in results_dict:
            results_dict[sample_name] = {}

        for qc_metric in config.keys():
            # PCT in the name is misleading. They are actually fractions!
            if qc_metric == "perc_Q30_BASES":
                total_reads = row["TOTAL_BASES"]
                q30_bases = row["Q30_BASES"]
                value = (q30_bases / total_reads) * 100
            elif qc_metric.startswith("PCT_"):
                value = row[qc_metric] * 100
            else:
                value = row[qc_metric]
            minimum = config[qc_metric]["min"]
            maximum = config[qc_metric]["max"]

            result = present_within_range(value, minimum, maximum)
            results_dict[sample_name][f"{qc_metric}_val"] = float(value)
            results_dict[sample_name][qc_metric] = "pass" if result else "fail"
            pass_fail.add(result)

    return results_dict, pass_fail


def picard(config_dict, asm_infile, qym_infile, wgs_infile, outfile):

    results_dict = {}
    pass_fail = set()

    # picard - AlignmentSummaryMetrics
    LOGGER.info("-" * 40)
    results_dict, pass_fail = check_thresholds(
        results_dict, pass_fail, asm_infile, config_dict["AlignmentSummaryMetrics"]
    )

    # picard - QualityYieldMetrics
    LOGGER.info("-" * 40)
    results_dict, pass_fail = check_thresholds(
        results_dict, pass_fail, qym_infile, config_dict["QualityYieldMetrics"]
    )

    # picard - CollectWgsMetrics
    LOGGER.info("-" * 40)
    results_dict, pass_fail = check_thresholds(
        results_dict, pass_fail, wgs_infile, config_dict["WgsMetrics"]
    )

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_fail) else "fail"

    return qc_check_status
