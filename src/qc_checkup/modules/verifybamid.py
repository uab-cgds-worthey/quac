"""
Read overall verifyBamID QC summary for a particular sample using multiqc's general stats data
and summarize the result.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def verifybamid(multiqc_df, sample_name, verifybamid_config, outfile):
    """
    Reads overall verifyBamID QC summary for a particular sample using multiqc's general stats data
    and summarizes the result.
    """

    LOGGER.info(
        f"Analyzing overall verifyBamID results for sample '{sample_name}' using multiqc general stats data"
    )

    if sample_name not in multiqc_df.index:
        LOGGER.exception(
            f"Sample '{sample_name}' not present in multiqc's general stats data. Exiting now"
        )
        raise SystemExit(1)

    verifybamid_prefix = "VerifyBAMID_mqc-generalstats-verifybamid"
    results_dict = {sample_name: {}}
    pass_fail = set()
    for qc_metric in verifybamid_config:
        value = multiqc_df.loc[sample_name, f"{verifybamid_prefix}-{qc_metric}"]

        minimum = verifybamid_config[qc_metric]["min"]
        maximum = verifybamid_config[qc_metric]["max"]

        result = present_within_range(value, minimum, maximum)
        results_dict[sample_name][f"{qc_metric}_val"] = float(value)
        results_dict[sample_name][qc_metric] = "pass" if result else "fail"
        pass_fail.add(result)

    # write results to file
    write_to_yaml_file(results_dict, outfile)

    # summarize results to one term
    qc_check_status = "pass" if all(pass_fail) else "fail"

    return qc_check_status
