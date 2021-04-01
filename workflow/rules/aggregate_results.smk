rule multiqc_initial_pass:
    input:
        OUT_DIR / "analysis" / "project_level_qc" / "somalier" / "relatedness" / "somalier.html",
        OUT_DIR / "analysis" / "project_level_qc" / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
        expand(str(OUT_DIR / "analysis" / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt"),
            sample=SAMPLES),
        expand(str(OUT_DIR / "analysis" / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html"),
            sample=SAMPLES),
        expand(str(OUT_DIR / "analysis" / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt"),
            sample=SAMPLES),
        expand(str(OUT_DIR / "analysis" / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry"),
            sample=SAMPLES),
        expand(str(OUT_DIR / "analysis" / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats"),
            sample=SAMPLES),
        # config_file = "configs/qc/multiqc_config.yaml",
        # rename_config = PROJECT_PATH + "/{all_samples}/qc/multiqc_initial_pass/multiqc_sample_rename_config/{all_samples}_rename_config.tsv",
    output:
        OUT_DIR / "analysis" / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc.html",
        # protected(PROJECT_PATH + "/{all_samples}/qc/multiqc_initial_pass/{all_samples}_multiqc_data/multiqc_general_stats.txt"),
        # protected(PROJECT_PATH + "/{all_samples}/qc/multiqc_initial_pass/{all_samples}_multiqc_data/multiqc_fastqc_trimmed.txt"),
        # protected(PROJECT_PATH + "/{all_samples}/qc/multiqc_initial_pass/{all_samples}_multiqc_data/multiqc_fastq_screen.txt"),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab (small var caller
    # pipeline repo)
    message:
        "Aggregates QC results using multiqc. First pass. Output will be used for the internal QC checkup. Sample: {wildcards.sample}"
    # params:
    #     # multiqc uses fastq's filenames to identify sample names. We renamed them based on units.tsv file,
    #     # using custom rename config file
    #     extra = lambda wildcards, input: f'--config {input.config_file} --sample-names {input.rename_config}'
    wrapper:
        "0.64.0/bio/multiqc"

