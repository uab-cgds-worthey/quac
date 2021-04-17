import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def process_AlignmentSummaryMetrics(report_file, picard_asm_config, outfile):

    LOGGER.info(f"Reading multiqc's Picard-AlignmentSummaryMetrics report file: {report_file}")

    df = pd.read_csv(report_file, sep="\t", index_col="Sample")
    # perc_columns = [x for x in df.columns if "percentage" in x]

    results_dict = {}
    pass_fail = set()
    for sample_name, row in df.iterrows():
        LOGGER.info(f"Working on sample: {sample_name}")

        results_dict[sample_name] = {}
        for qc_metric in picard_asm_config.keys():
            # PCT in the name is misleading. They are actually fractions!
            if qc_metric.startswith("PCT_"):
                value = row[qc_metric] * 100
            else:
                value = row[qc_metric]
            minimum = picard_asm_config[qc_metric]["min"]
            maximum = picard_asm_config[qc_metric]["max"]

            result = present_within_range(value, minimum, maximum)
            results_dict[sample_name][f"{qc_metric}_val"] = float(value)
            results_dict[sample_name][qc_metric] = "pass" if result else "fail"
            pass_fail.add(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_fail) else "fail"

    return qc_check_status
