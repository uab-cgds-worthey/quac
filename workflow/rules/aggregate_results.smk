##########################   Single-sample-level QC aggregation  ##########################
rule multiqc_by_sample_initial_pass:
    input:
        get_small_var_pipeline_targets,
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        multiqc_config=WORKFLOW_PATH / "configs" / "multiqc_config.yaml",
        rename_config=PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc.html"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc_trimmed.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_AlignmentSummaryMetrics.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_QualityYieldMetrics.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_wgsmetrics.txt"),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab (small var caller pipeline repo)
    message:
        "Aggregates QC results using multiqc. First pass. Output will be used for the internal QC checkup. Sample: {wildcards.sample}"
    params:
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file
        extra=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}",
    wrapper:
        "0.64.0/bio/multiqc"


rule qc_checkup:
    input:
        qc_config=WORKFLOW_PATH / "configs" / "qc_checkup" / "qc_checkup_config.yaml",
        multiqc_stats=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt",
        fastqc_trimmed=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc_trimmed.txt",
        fastq_screen=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt",
        qualimap=OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "genome_results.txt",
        picard_asm=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_AlignmentSummaryMetrics.txt",
        picard_qym=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_QualityYieldMetrics.txt",
        picard_wgs=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_wgsmetrics.txt",
        bcftools_index=OUT_DIR / "{sample}" / "qc" / "bcftools-index" / "{sample}.bcftools.index.tsv",
    output:
        protected(
            expand(
                OUT_DIR / "{{sample}}" / "qc" / "qc_checkup" / "qc_checkup_{suffix}.yaml",
                suffix=["overall_summary", "fastqc", "fastq_screen", "qualimap_overall", "qualimap_chromosome_stats", "variant_per_contig"],
            )
        ),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Runs QC checkup on various QC tool output, based on custom defined QC thresholds. "
        "Note that this will NOT work as expected for multi-sample analysis. Sample: {wildcards.sample}"
    params:
        sample="{sample}",
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
    conda:
        str(WORKFLOW_PATH / "configs/env/qc_checkup.yaml")
    shell:
        r"""
        python src/qc_checkup/qc_checkup.py \
            --config {input.qc_config} \
            --multiqc_stats {input.multiqc_stats} \
            --fastqc {input.fastqc_trimmed} \
            --fastq_screen {input.fastq_screen} \
            --qualimap {input.qualimap} \
            --picard_asm {input.picard_asm} \
            --picard_qym {input.picard_qym} \
            --picard_wgs {input.picard_wgs} \
            --bcftools_index {input.bcftools_index} \
            --sample {params.sample} \
            --outdir {params.outdir}
        """


rule multiqc_by_sample_final_pass:
    input:
        get_small_var_pipeline_targets,
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        OUT_DIR / "{sample}" / "qc" / "qc_checkup" / "qc_checkup_overall_summary.yaml",
        multiqc_config=WORKFLOW_PATH / "configs" / "multiqc_config.yaml",
        rename_config=PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_final_pass" / "{sample}_multiqc.html"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_final_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt"),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Aggregates QC results using multiqc. Final pass, where QC checkup results are also aggregated. Sample: {wildcards.sample}"
    params:
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file
        extra=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}",
    wrapper:
        "0.64.0/bio/multiqc"


##########################   Multi-sample QC aggregation  ##########################
localrules:
    aggregate_sample_rename_configs,


rule aggregate_sample_rename_configs:
    input:
        expand(
            PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
            sample=SAMPLES,
        ),
    output:
        protected(OUT_DIR / "project_level_qc" / "multiqc" / "aggregated_rename_configs.tsv"),
    message:
        "Aggregate all sample rename-config files."
    run:
        aggregate_rename_configs(input, output[0])


rule multiqc_aggregation_all_samples:
    input:
        expand(
            [
                PROJECT_PATH / "{sample}" / "qc" / "fastqc-raw" / "{sample}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{sample}" / "qc" / "fastqc-trimmed" / "{sample}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{sample}" / "qc" / "fastq_screen-trimmed" / "{sample}-{unit}-{read}_screen.txt",
                PROJECT_PATH / "{sample}" / "qc" / "dedup" / "{sample}-{unit}.metrics.txt",
                OUT_DIR / "project_level_qc" / "somalier" / "relatedness" / "somalier.html",
                OUT_DIR / "project_level_qc" / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
                OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
                OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
                OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
                OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
                OUT_DIR / "{sample}" / "qc" / "qc_checkup" / "qc_checkup_overall_summary.yaml",
            ],
            sample=SAMPLES,
            unit=[1],
            read=["R1", "R2"],
        ),
        multiqc_config=WORKFLOW_PATH / "configs" / "multiqc_config.yaml",
        rename_config=OUT_DIR / "project_level_qc" / "multiqc" / "aggregated_rename_configs.tsv",
    output:
        protected(OUT_DIR / "project_level_qc" / "multiqc" / "multiqc_report.html"),
    message:
        "Running multiqc for all samples"
    params:
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file
        extra=(
            lambda wildcards, input: f'--config {input.multiqc_config} \
                                                            --sample-names {input.rename_config} \
                                                            --cl_config "max_table_rows: 2000"'
        ),
    wrapper:
        "0.64.0/bio/multiqc"
