"""
Creates multiqc config file based on jinja templating and values from qc-checkup config file.
"""

from jinja2 import Template, StrictUndefined
import yaml


def main(template_f, qc_config, outfile):

    with open(qc_config) as file_handle:
        config = yaml.safe_load(file_handle)

    with open(template_f) as file_:
        template = Template(file_.read(), undefined=StrictUndefined)

    data = template.render(
        # fastq screen
        fastq_screen_human_min=config["fastq_screen"]["Human percentage"]["min"],
        fastq_screen_human_max=config["fastq_screen"]["Human percentage"]["max"],
        fastq_screen_mouse_min=config["fastq_screen"]["Mouse percentage"]["min"],
        fastq_screen_mouse_max=config["fastq_screen"]["Mouse percentage"]["max"],
        fastq_screen_rat_min=config["fastq_screen"]["Rat percentage"]["min"],
        fastq_screen_rat_max=config["fastq_screen"]["Rat percentage"]["max"],
        fastq_screen_drosophila_min=config["fastq_screen"]["Drosophila percentage"]["min"],
        fastq_screen_drosophila_max=config["fastq_screen"]["Drosophila percentage"]["max"],
        fastq_screen_arabidopsis_min=config["fastq_screen"]["Arabidopsis percentage"]["min"],
        fastq_screen_arabidopsis_max=config["fastq_screen"]["Arabidopsis percentage"]["max"],
        fastq_screen_nohits_min=config["fastq_screen"]["No hits percentage"]["min"],
        fastq_screen_nohits_max=config["fastq_screen"]["No hits percentage"]["max"],
        fastq_screen_others_min=config["fastq_screen"]["others percentage"]["min"],
        fastq_screen_others_max=config["fastq_screen"]["others percentage"]["max"],
        # qualimap
        qualimap_avg_gc_min=config["qualimap"]["avg_gc"]["min"],
        qualimap_avg_gc_max=config["qualimap"]["avg_gc"]["max"],
        qualimap_mean_coverage_min=config["qualimap"]["mean_coverage"]["min"],
        qualimap_median_coverage_min=config["qualimap"]["median_coverage"]["min"],
        qualimap_mean_median_coverage_ratio_min=config["qualimap"]["mean_cov:median_cov"]["min"],
        qualimap_mean_median_coverage_ratio_max=config["qualimap"]["mean_cov:median_cov"]["max"],
        qualimap_median_insert_size_min=config["qualimap"]["median_insert_size"]["min"],
        qualimap_percentage_aligned_min=config["qualimap"]["percentage_aligned"]["min"],
        qualimap_percentage_aligned_max=config["qualimap"]["percentage_aligned"]["max"],
        # picard_AlignmentSummaryMetrics
        picard_asm_PCT_PF_READS_ALIGNED_min=config["picard"]["AlignmentSummaryMetrics"][
            "PCT_PF_READS_ALIGNED"
        ]["min"],
        picard_asm_PCT_PF_READS_ALIGNED_max=config["picard"]["AlignmentSummaryMetrics"][
            "PCT_PF_READS_ALIGNED"
        ]["max"],
        picard_asm_PF_HQ_ALIGNED_Q20_BASES_min=config["picard"]["AlignmentSummaryMetrics"][
            "PF_HQ_ALIGNED_Q20_BASES"
        ]["min"],
        picard_asm_PF_HQ_ALIGNED_Q20_BASES_max=config["picard"]["AlignmentSummaryMetrics"][
            "PF_HQ_ALIGNED_Q20_BASES"
        ]["max"],
        picard_asm_PCT_ADAPTER_min=config["picard"]["AlignmentSummaryMetrics"]["PCT_ADAPTER"][
            "min"
        ],
        picard_asm_PCT_ADAPTER_max=config["picard"]["AlignmentSummaryMetrics"]["PCT_ADAPTER"][
            "max"
        ],
        picard_asm_PCT_CHIMERAS_min=config["picard"]["AlignmentSummaryMetrics"]["PCT_CHIMERAS"][
            "min"
        ],
        picard_asm_PCT_CHIMERAS_max=config["picard"]["AlignmentSummaryMetrics"]["PCT_CHIMERAS"][
            "max"
        ],
        # picard_QualityYieldMetrics
        picard_qym_Q30_BASES_min=config["picard"]["QualityYieldMetrics"]["Q30_BASES"]["min"],
        picard_qym_perc_Q30_BASES_min=config["picard"]["QualityYieldMetrics"]["perc_Q30_BASES"][
            "min"
        ],
        # picard_WgsMetrics
        picard_wgs_PCT_EXC_TOTAL_min=config["picard"]["WgsMetrics"]["PCT_EXC_TOTAL"]["min"],
        picard_wgs_PCT_EXC_TOTAL_max=config["picard"]["WgsMetrics"]["PCT_EXC_TOTAL"]["max"],
        picard_wgs_PCT_15X_min=config["picard"]["WgsMetrics"]["PCT_15X"]["min"],
        picard_wgs_PCT_15X_max=config["picard"]["WgsMetrics"]["PCT_15X"]["max"],
        # verifybamid
        verifybamid_freemix_min=config["verifybamid"]["FREEMIX"]["min"],
        verifybamid_freemix_max=config["verifybamid"]["FREEMIX"]["max"],
        # bcftools_stats
        bcftools_stats_number_of_records_min=config["bcftools_stats"]["number_of_records"]["min"],
        bcftools_stats_number_of_records_max=config["bcftools_stats"]["number_of_records"]["max"],
        bcftools_stats_number_of_SNPs_min=config["bcftools_stats"]["number_of_SNPs"]["min"],
        bcftools_stats_number_of_SNPs_max=config["bcftools_stats"]["number_of_SNPs"]["max"],
        bcftools_stats_number_of_indels_min=config["bcftools_stats"]["number_of_indels"]["min"],
        bcftools_stats_number_of_indels_max=config["bcftools_stats"]["number_of_indels"]["max"],
        bcftools_stats_perc_snps_min=config["bcftools_stats"]["perc_snps"]["min"],
        bcftools_stats_perc_snps_max=config["bcftools_stats"]["perc_snps"]["max"],
        bcftools_stats_perc_indels_min=config["bcftools_stats"]["perc_indels"]["min"],
        bcftools_stats_perc_indels_max=config["bcftools_stats"]["perc_indels"]["max"],
        bcftools_stats_tstv_min=config["bcftools_stats"]["tstv"]["min"],
        bcftools_stats_tstv_max=config["bcftools_stats"]["tstv"]["max"],
        bcftools_stats_heterozygosity_ratio_min=config["bcftools_stats"]["heterozygosity_ratio"][
            "min"
        ],
        # variant freq per contig
        perc_variant_per_contig_chr1_min=config["perc_variant_per_contig"]["chr1"]["min"],
        perc_variant_per_contig_chr1_max=config["perc_variant_per_contig"]["chr1"]["max"],
        perc_variant_per_contig_chr2_min=config["perc_variant_per_contig"]["chr2"]["min"],
        perc_variant_per_contig_chr2_max=config["perc_variant_per_contig"]["chr2"]["max"],
        perc_variant_per_contig_chr3_min=config["perc_variant_per_contig"]["chr3"]["min"],
        perc_variant_per_contig_chr3_max=config["perc_variant_per_contig"]["chr3"]["max"],
        perc_variant_per_contig_chr4_min=config["perc_variant_per_contig"]["chr4"]["min"],
        perc_variant_per_contig_chr4_max=config["perc_variant_per_contig"]["chr4"]["max"],
        perc_variant_per_contig_chr5_min=config["perc_variant_per_contig"]["chr5"]["min"],
        perc_variant_per_contig_chr5_max=config["perc_variant_per_contig"]["chr5"]["max"],
        perc_variant_per_contig_chr6_min=config["perc_variant_per_contig"]["chr6"]["min"],
        perc_variant_per_contig_chr6_max=config["perc_variant_per_contig"]["chr6"]["max"],
        perc_variant_per_contig_chr7_min=config["perc_variant_per_contig"]["chr7"]["min"],
        perc_variant_per_contig_chr7_max=config["perc_variant_per_contig"]["chr7"]["max"],
        perc_variant_per_contig_chr8_min=config["perc_variant_per_contig"]["chr8"]["min"],
        perc_variant_per_contig_chr8_max=config["perc_variant_per_contig"]["chr8"]["max"],
        perc_variant_per_contig_chr9_min=config["perc_variant_per_contig"]["chr9"]["min"],
        perc_variant_per_contig_chr9_max=config["perc_variant_per_contig"]["chr9"]["max"],
        perc_variant_per_contig_chr10_min=config["perc_variant_per_contig"]["chr10"]["min"],
        perc_variant_per_contig_chr10_max=config["perc_variant_per_contig"]["chr10"]["max"],
        perc_variant_per_contig_chr11_min=config["perc_variant_per_contig"]["chr11"]["min"],
        perc_variant_per_contig_chr11_max=config["perc_variant_per_contig"]["chr11"]["max"],
        perc_variant_per_contig_chr12_min=config["perc_variant_per_contig"]["chr12"]["min"],
        perc_variant_per_contig_chr12_max=config["perc_variant_per_contig"]["chr12"]["max"],
        perc_variant_per_contig_chr13_min=config["perc_variant_per_contig"]["chr13"]["min"],
        perc_variant_per_contig_chr13_max=config["perc_variant_per_contig"]["chr13"]["max"],
        perc_variant_per_contig_chr14_min=config["perc_variant_per_contig"]["chr14"]["min"],
        perc_variant_per_contig_chr14_max=config["perc_variant_per_contig"]["chr14"]["max"],
        perc_variant_per_contig_chr15_min=config["perc_variant_per_contig"]["chr15"]["min"],
        perc_variant_per_contig_chr15_max=config["perc_variant_per_contig"]["chr15"]["max"],
        perc_variant_per_contig_chr16_min=config["perc_variant_per_contig"]["chr16"]["min"],
        perc_variant_per_contig_chr16_max=config["perc_variant_per_contig"]["chr16"]["max"],
        perc_variant_per_contig_chr17_min=config["perc_variant_per_contig"]["chr17"]["min"],
        perc_variant_per_contig_chr17_max=config["perc_variant_per_contig"]["chr17"]["max"],
        perc_variant_per_contig_chr18_min=config["perc_variant_per_contig"]["chr18"]["min"],
        perc_variant_per_contig_chr18_max=config["perc_variant_per_contig"]["chr18"]["max"],
        perc_variant_per_contig_chr19_min=config["perc_variant_per_contig"]["chr19"]["min"],
        perc_variant_per_contig_chr19_max=config["perc_variant_per_contig"]["chr19"]["max"],
        perc_variant_per_contig_chr20_min=config["perc_variant_per_contig"]["chr20"]["min"],
        perc_variant_per_contig_chr20_max=config["perc_variant_per_contig"]["chr20"]["max"],
        perc_variant_per_contig_chr21_min=config["perc_variant_per_contig"]["chr21"]["min"],
        perc_variant_per_contig_chr21_max=config["perc_variant_per_contig"]["chr21"]["max"],
        perc_variant_per_contig_chr22_min=config["perc_variant_per_contig"]["chr22"]["min"],
        perc_variant_per_contig_chr22_max=config["perc_variant_per_contig"]["chr22"]["max"],
        perc_variant_per_contig_chrX_min=config["perc_variant_per_contig"]["chrX"]["min"],
        perc_variant_per_contig_chrX_max=config["perc_variant_per_contig"]["chrX"]["max"],
        perc_variant_per_contig_chrY_min=config["perc_variant_per_contig"]["chrY"]["min"],
        perc_variant_per_contig_chrY_max=config["perc_variant_per_contig"]["chrY"]["max"],
        #
        undefined=StrictUndefined,
    )

    with open(outfile, "w") as fh:
        fh.write(data)

    return None


if __name__ == "__main__":
    TEMPLATE_F = "configs/multiqc_config_template.jinja2"
    QC_CONFIG = "configs/qc_checkup/qc_checkup_config.yaml"
    OUTFILE = "configs/multiqc_config.yaml"
    main(TEMPLATE_F, QC_CONFIG, OUTFILE)
