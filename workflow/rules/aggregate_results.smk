rule multiqc_initial_pass:
    input:
        expand(
            str(
                PROJECT_PATH
                / "{{sample}}"
                / "qc"
                / "fastqc-raw"
                / "{{sample}}-{unit}-{read}_fastqc.zip"
            ),
            unit=[1,2],
            read=["R1", "R2"],
        ),
        expand(
            str(
                PROJECT_PATH
                / "{{sample}}"
                / "qc"
                / "fastqc-trimmed"
                / "{{sample}}-{unit}-{read}_fastqc.zip"
            ),
            unit=[1,2],
            read=["R1", "R2"],
        ),
        expand(
            str(
                PROJECT_PATH
                / "{{sample}}"
                / "qc"
                / "fastq_screen-trimmed"
                / "{{sample}}-{unit}-{read}_screen.txt"
            ),
            unit=[1,2],
            read=["R1", "R2"],
        ),
        OUT_DIR / "project_level_qc" / "somalier" / "relatedness" / "somalier.html",
        OUT_DIR / "project_level_qc" / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        config_file = "configs/multiqc_config.yaml",
        rename_config=(
            PROJECT_PATH
            / "{sample}"
            / "qc"
            / "multiqc_initial_pass"
            / "multiqc_sample_rename_config"
            / "{sample}_rename_config.tsv"
        ),
    output:
        OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc.html",
        OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt",
        OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc_trimmed.txt",
        OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt",
    # wildcard_constraints: #TODO - fix unit wildcard
    #     unit="\d+",
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
