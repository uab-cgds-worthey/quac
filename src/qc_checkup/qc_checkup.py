"""
Analyzes results from various QC output files, and identifies
if they have passed criteria defined in QC-checkup config file.
Writes results in mutliqc-friendly format.

NOTE: Multiqc config file has hard-coded parameters, which is based
on the QC-checkup config file. If parameters in QC-checkup config
file get modified, multiqc config file may need to be edited as well.
Helper script create_mutliqc_configs.py can help with this task.
"""

import argparse
from pathlib import Path
from modules import fastqc
from modules import fastq_screen
from modules import multiqc_general_stats
from modules import qualimap
from modules import picard
from modules import variant_freq_by_contig
from common import get_configs, is_valid_file, write_to_yaml_file, qc_logger


def main(
    config_f,
    fastqc_f,
    fastq_screen_f,
    multiqc_stats_f,
    qualimap_f,
    picard_dup_f,
    picard_asm_f,
    picard_qym_f,
    picard_wgs_f,
    bcftools_index_f,
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
    qc_checks_dict["qualimap_overall"] = multiqc_general_stats.check_thresholds(
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

    # picard
    picard_outfile = f"{out_filepath_prefix}_picard.yaml"
    qc_checks_dict["picard"] = picard.summarize_results(
        config_dict["picard"], picard_asm_f, picard_qym_f, picard_wgs_f, picard_outfile
    )

    # picard duplication
    LOGGER.info("-" * 80)
    picard_dup_outfile = f"{out_filepath_prefix}_picard_dups.yaml"
    qc_checks_dict["picard_dups"] = picard.duplication(
        picard_dup_f, config_dict["picard"]["MarkDuplicates"], picard_dup_outfile
    )

    # verifyBamID
    LOGGER.info("-" * 80)
    verifybamid_outfile = f"{out_filepath_prefix}_verifybamid.yaml"
    verifybamid_prefix = "VerifyBAMID_mqc-generalstats-verifybamid"
    qc_checks_dict["verifybamid"] = multiqc_general_stats.check_thresholds(
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
    qc_checks_dict["bcftools_stats"] = multiqc_general_stats.check_thresholds(
        multiqc_general_stats_df,
        sample,
        "bcftools_stats",
        config_dict["bcftools_stats"],
        bcftools_stats_prefix,
        bcftools_stats_outfile,
    )

    # bcftools-index for per-contig variant frequency
    bcftools_index_outfile = f"{out_filepath_prefix}_variant_per_contig.yaml"
    qc_checks_dict["variant_per_contig"] = variant_freq_by_contig.stat_by_chromosome(
        bcftools_index_f,
        sample,
        config_dict["perc_variant_per_contig"],
        bcftools_index_outfile,
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
        help="Fastqc summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--fastq_screen",
        help="Fastq screen summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--qualimap",
        help="Report file generated by Qualimap",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_dups",
        help="Picard Duplicates summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_asm",
        help="Picard AlignmentSummaryMetrics summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_qym",
        help="Picard QualityYieldMetrics summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--picard_wgs",
        help="Picard WgsMetrics summary file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--bcftools_index",
        help="Index file generated by Bcftools-index",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--multiqc_stats",
        help="General stats txt report file generated by multiqc",
        type=lambda x: is_valid_file(PARSER, x),
        metavar="",
    )

    PARSER.add_argument(
        "--sample",
        help="Sample name. This will be retrieve data from multiqc general stats data",
        type=str,
        metavar="",
    )

    PARSER.add_argument(
        "--outdir",
        help="Directory path to store output files",
        type=str,
        metavar="",
    )

    args = PARSER.parse_args()

    CONFIG = args.config
    FASTQC = args.fastqc
    FASTQ_SCREEN = args.fastq_screen
    MULTIQC_STATS_F = args.multiqc_stats
    QUALIMAP_F = args.qualimap
    PICARD_DUP_F = args.picard_dups
    PICARD_ASM_F = args.picard_asm
    PICARD_QYM_F = args.picard_qym
    PICARD_WGS_F = args.picard_wgs
    BCFTOOLS_INDEX_F = args.bcftools_index
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
        PICARD_DUP_F,
        PICARD_ASM_F,
        PICARD_QYM_F,
        PICARD_WGS_F,
        BCFTOOLS_INDEX_F,
        OUT_DIR,
        SAMPLE,
    )
