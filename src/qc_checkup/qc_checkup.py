"""
Analyzes results from various QC output files, and identifies
if they have passed criteria defined in QC-checkup config file.
Writes results in mutliqc-friendly format.

NOTE: Multiqc config file has hard-coded parameters, which is based
on the QC-checkup config file. If parameters in QC-checkup config
file get modified, multiqc config file may need to be edited as well.
"""

import argparse
from pathlib import Path
from modules import fastqc
from modules import fastq_screen
from modules import multiqc_general_stats
from modules import qualimap
from modules import picard
from common import get_configs, is_valid_file, write_to_yaml_file, qc_logger


def main(
    config_f,
    fastqc_f,
    fastq_screen_f,
    multiqc_stats_f,
    qualimap_f,
    picard_asm_f,
    picard_qym_f,
    outdir,
    sample,
):

    # read config from file
    config_dict = get_configs(config_f)

    out_filepath_prefix = str(Path(outdir) / "qc_checkup")
    qc_checks_dict = {}

    # fastqc
    LOGGER.info("-" * 80)
    fastqc_outfile = f"{out_filepath_prefix}_fastqc.yaml"
    qc_checks_dict["fastqc"] = fastqc.fastqc(fastqc_f, config_dict["fastqc"], fastqc_outfile)

    # fastq screen
    LOGGER.info("-" * 80)
    fastq_screen_outfile = f"{out_filepath_prefix}_fastq_screen.yaml"
    qc_checks_dict["fastq_screen"] = fastq_screen.fastq_screen(
        fastq_screen_f, config_dict["fastq_screen"], fastq_screen_outfile
    )

    # read multiqc's general stats
    LOGGER.info("-" * 80)
    multiqc_general_stats_df = multiqc_general_stats.read_stats(multiqc_stats_f)

    # qualimap - overall stats
    LOGGER.info("-" * 80)
    qualimap_overall_outfile = f"{out_filepath_prefix}_qualimap_overall.yaml"
    qualimap_prefix = "QualiMap_mqc-generalstats-qualimap"
    qc_checks_dict["qualimap_overall"] = multiqc_general_stats.test_for_range(
        multiqc_general_stats_df,
        sample,
        "qualimap",
        config_dict["qualimap"],
        qualimap_prefix,
        qualimap_overall_outfile,
    )

    # qualimap - stats by chromosome
    LOGGER.info("-" * 80)
    qualimap_by_chrom_outfile = f"{out_filepath_prefix}_qualimap_chromosome_stats.yaml"
    qc_checks_dict["qualimap_chromosome_specific"] = qualimap.stat_by_chromosome(
        qualimap_f, sample, config_dict["qualimap"], qualimap_by_chrom_outfile
    )

    # # picard - AlignmentSummaryMetrics
    # LOGGER.info("-" * 80)
    # picard_asm_outfile = f"{out_filepath_prefix}_picard_AlignmentSummaryMetrics.yaml"
    # qc_checks_dict["picard_asm"] = picard.check_metrics(
    #     picard_asm_f, config_dict["picard"]["AlignmentSummaryMetrics"], picard_asm_outfile
    # )

    # # picard - QualityYieldMetrics
    # LOGGER.info("-" * 80)
    # picard_qym_outfile = f"{out_filepath_prefix}_picard_QualityYieldMetrics.yaml"
    # qc_checks_dict["picard_qym"] = picard.check_metrics(
    #     picard_qym_f, config_dict["picard"]["QualityYieldMetrics"], picard_qym_outfile
    # )

    picard_outfile = f"{out_filepath_prefix}_picard.yaml"
    qc_checks_dict["picard"] = picard.picard(
        config_dict["picard"], picard_asm_f, picard_qym_f, picard_outfile
    )

    # verifyBamID
    LOGGER.info("-" * 80)
    verifybamid_outfile = f"{out_filepath_prefix}_verifybamid.yaml"
    verifybamid_prefix = "VerifyBAMID_mqc-generalstats-verifybamid"
    qc_checks_dict["verifybamid"] = multiqc_general_stats.test_for_range(
        multiqc_general_stats_df,
        sample,
        "verifybamid",
        config_dict["verifybamid"],
        verifybamid_prefix,
        verifybamid_outfile,
    )

    # bcftools-stats
    LOGGER.info("-" * 80)
    bcftools_stats_outfile = f"{out_filepath_prefix}_bcftools_stats.yaml"
    bcftools_stats_prefix = "Bcftools Stats_mqc-generalstats-bcftools_stats"
    qc_checks_dict["bcftools_stats"] = multiqc_general_stats.test_for_range(
        multiqc_general_stats_df,
        sample,
        "bcftools_stats",
        config_dict["bcftools_stats"],
        bcftools_stats_prefix,
        bcftools_stats_outfile,
    )

    # write QC check results to file
    LOGGER.info("-" * 80)
    sample_qc_checks_dict = {sample: qc_checks_dict}  # multiqc-friendly format
    overall_qc_checks_outfile = f"{out_filepath_prefix}_overall_summary.yaml"
    write_to_yaml_file(sample_qc_checks_dict, overall_qc_checks_outfile)

    return None


if __name__ == "__main__":

    PARSER = argparse.ArgumentParser(
        description="Analyzes output from several QC tools' output, "
        "identifies if they pass CGDS's QC thresholds, "
        "and writes results in mutliqc-friendly format",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    PARSER.add_argument(
        "--config",
        help="Config yaml file with QC thresholds",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--fastqc",
        help="Fastqc report file from multiqc output",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--fastq_screen",
        help="Fastq screen txt report file",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--qualimap",
        help="Qualimap txt report file",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_asm",
        help="Picard AlignmentSummaryMetrics report file from multiqc output",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_qym",
        help="Picard QualityYieldMetrics report file from multiqc output",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--multiqc_stats",
        help="Multiqc general stats txt report file",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--sample",
        help="Sample name. This will be retrieve qualimap data from multiqc general stats data",
        type=str,
        metavar="",
    )

    PARSER.add_argument(
        "--outdir",
        help="Directory where result files will be stored",
        type=str,
        metavar="",
    )

    args = PARSER.parse_args()

    CONFIG = args.config
    FASTQC = args.fastqc
    FASTQ_SCREEN = args.fastq_screen
    MULTIQC_STATS_F = args.multiqc_stats
    QUALIMAP_F = args.qualimap
    PICARD_ASM_F = args.picard_asm
    PICARD_QYM_F = args.picard_qym
    SAMPLE = args.sample
    OUT_DIR = args.outdir

    # setup logging
    LOGGER = qc_logger(__name__)

    main(
        CONFIG,
        FASTQC,
        FASTQ_SCREEN,
        MULTIQC_STATS_F,
        QUALIMAP_F,
        PICARD_ASM_F,
        PICARD_QYM_F,
        OUT_DIR,
        SAMPLE,
    )
