"""
Read multiqc's fastq_screen report and summarize the result of all fastq files in it.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def fastq_screen(report_file, fastq_screen_config, outfile):

    LOGGER.info(f"Reading multiqc's fastq_screen report file: {report_file}")

    df = pd.read_csv(report_file, sep="\t", index_col="Sample")
    perc_columns = [x for x in df.columns if "percentage" in x]

    results_dict = {}
    pass_or_fail = set()
    for sample_name, row in df.iterrows():
        LOGGER.info(f"Working on sample: {sample_name}")

        results_dict[sample_name] = {}
        for column in perc_columns:
            if column in fastq_screen_config:
                config_key = column
            else:
                config_key = "others percentage"

            value = row[column]
            minimum = fastq_screen_config[config_key]["min"]
            maximum = fastq_screen_config[config_key]["max"]

            result = present_within_range(value, minimum, maximum)
            renamed_column = "%" + column.replace(" percentage", "")
            results_dict[sample_name][f"{renamed_column}_val"] = float(value)
            results_dict[sample_name][renamed_column] = "pass" if result else "fail"
            pass_or_fail.add(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_or_fail) else "fail"

    return qc_check_status
