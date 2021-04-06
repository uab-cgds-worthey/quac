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
