"""
Analyze chromosome-level coverage QC using qualimap report file and summarize the result.
"""

import pandas as pd
from common import present_within_range, qc_logger, write_to_yaml_file

# setup logging
LOGGER = qc_logger(__name__)


def stat_by_chromosome(qualimap_f, sample_name, qualimap_config, outfile):
    """
    Analyzes chromosome-level coverage QC using qualimap report file
    and summarize the result.

    Args:
        qualimap_f (str): Qualimap report file
        sample_name (str): sample name
        qualimap_config (dict): Thresholds for QC metrics
        outfile (str): Output filepath

    Returns:
        str: Result stating if sample has passed or failed the tests (pass, fail).
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
