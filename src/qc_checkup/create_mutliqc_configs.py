from jinja2 import Template
import yaml


def main(template_f, qc_config):

    with open(qc_config) as file_handle:
        config = yaml.safe_load(file_handle)

    with open(template_f) as file_:
        template = Template(file_.read())

    data = template.render(
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
        qualimap_avg_gc_min=config["qualimap"]["avg_gc"]["min"],
        qualimap_avg_gc_max=config["qualimap"]["avg_gc"]["max"],
        qualimap_mean_coverage_min=config["qualimap"]["mean_coverage"]["min"],
        qualimap_median_coverage_min=config["qualimap"]["median_coverage"]["min"],
        qualimap_percentage_aligned_min=config["qualimap"]["percentage_aligned"]["min"],
        qualimap_percentage_aligned_max=config["qualimap"]["percentage_aligned"]["max"],
    )

    with open("test.yaml", "w") as fh:
        fh.write(data)

    return None


if __name__ == "__main__":
    TEMPLATE_F = "configs/multiqc_config_template.jinja2"
    QC_CONFIG = "configs/qc_checkup/qc_checkup_config.yaml"
    main(TEMPLATE_F, QC_CONFIG)
