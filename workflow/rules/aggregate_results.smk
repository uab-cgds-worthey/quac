##########################     Create Multiqc config file    ##########################
localrules:
    create_multiqc_config,

rule create_multiqc_config:
    input:
        script=WORKFLOW_PATH / "src" / "quac_watch" / "create_mutliqc_configs.py",
        template=WORKFLOW_PATH / "configs" / "multiqc_config_template.jinja2",
        quac_watch_config=config["quac_watch_config"],
    output:
        temp(MULTIQC_CONFIG_FILE)
    message:
        "Creates multiqc configs from jinja-template based on QuaC-Watch configs"
    singularity:
        "docker://quay.io/biocontainers/mulled-v2-78a02249d8cc4e85718933e89cf41d0e6686ac25:70df245247aac9844ee84a9da1e96322a24c1f34-0"
    shell:
        r"""
        python {input.script} \
            --template_f {input.template} \
            --qc_config {input.quac_watch_config} \
            --outfile {output}
        """


##########################   Single-sample-level QC aggregation  ##########################
rule multiqc_by_sample_initial_pass:
    input:
        get_small_var_pipeline_targets if INCLUDE_PRIOR_QC_DATA else [],
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv" if ALLOW_SAMPLE_RENAMING else [],
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc.html"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc_trimmed.txt") if INCLUDE_PRIOR_QC_DATA else [],
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt") if INCLUDE_PRIOR_QC_DATA else [],
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_AlignmentSummaryMetrics.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_QualityYieldMetrics.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_wgsmetrics.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_dups.txt") if INCLUDE_PRIOR_QC_DATA else [],
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab (small var caller pipeline repo)
    message:
        "Aggregates QC results using multiqc. First pass. Output will be used for the QuaC-Watch. Sample: {wildcards.sample}"
    params:
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
        outfilename=lambda wildcards, output: str(Path(output[0]).name),
        in_dirs=lambda wildcards, input: set(Path(fp).parent for fp in input),
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file, if needed
        extra_config=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}" if ALLOW_SAMPLE_RENAMING else f"--config {input.multiqc_config}",
    singularity:
        "docker://quay.io/biocontainers/multiqc:1.9--py_1"
    shell:
        r"""
        multiqc \
            {params.extra_config} \
            --force \
            --outdir {params.outdir} \
            --filename {params.outfilename} \
            {params.in_dirs}
        """

rule quac_watch:
    input:
        qc_config=config["quac_watch_config"],
        multiqc_stats=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt",
        fastqc_trimmed=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc_trimmed.txt" if INCLUDE_PRIOR_QC_DATA else [],
        fastq_screen=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt" if INCLUDE_PRIOR_QC_DATA else [],
        qualimap=OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "genome_results.txt",
        picard_asm=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_AlignmentSummaryMetrics.txt",
        picard_qym=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_QualityYieldMetrics.txt",
        picard_wgs=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_wgsmetrics.txt",
        picard_dups=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_picard_dups.txt" if INCLUDE_PRIOR_QC_DATA else [],
        bcftools_index=OUT_DIR / "{sample}" / "qc" / "bcftools-index" / "{sample}.bcftools.index.tsv",
    output:
        protected(
            expand(
                OUT_DIR / "{{sample}}" / "qc" / "quac_watch" / "quac_watch_{suffix}.yaml",
                suffix=[
                    "overall_summary",
                    "qualimap_overall",
                    "qualimap_chromosome_stats",
                    "picard",
                    "verifybamid",
                    "bcftools_stats",
                    "variant_per_contig",
                ],
            )
        ),
        protected(
            expand(
                OUT_DIR / "{{sample}}" / "qc" / "quac_watch" / "quac_watch_{suffix}.yaml",
                suffix=[ "fastqc", "fastq_screen", "picard_dups"],
            )
        ) if INCLUDE_PRIOR_QC_DATA else [],
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Runs QuaC-Watch on various QC tool output, based on custom defined QC thresholds. "
        "Note that this will NOT work as expected for multi-sample analysis. Sample: {wildcards.sample}"
    params:
        sample="{sample}",
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
        extra=lambda wildcards, input: f'--fastqc "{input.fastqc_trimmed}" --fastq_screen "{input.fastq_screen}" --picard_dups "{input.picard_dups}"' if INCLUDE_PRIOR_QC_DATA else "",
    singularity:
        "docker://quay.io/biocontainers/mulled-v2-78a02249d8cc4e85718933e89cf41d0e6686ac25:70df245247aac9844ee84a9da1e96322a24c1f34-0"
    shell:
        r"""
        python src/quac_watch/quac_watch.py \
            --config {input.qc_config} \
            --multiqc_stats {input.multiqc_stats} \
            --qualimap {input.qualimap} \
            --picard_asm {input.picard_asm} \
            --picard_qym {input.picard_qym} \
            --picard_wgs {input.picard_wgs} \
            --bcftools_index {input.bcftools_index} \
            {params.extra} \
            --sample {params.sample} \
            --outdir {params.outdir}
        """


rule multiqc_by_sample_final_pass:
    input:
        get_small_var_pipeline_targets if INCLUDE_PRIOR_QC_DATA else [],
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        OUT_DIR / "{sample}" / "qc" / "quac_watch" / "quac_watch_overall_summary.yaml",
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv" if ALLOW_SAMPLE_RENAMING else [],
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_final_pass" / "{sample}_multiqc.html"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_final_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt"),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Aggregates QC results using multiqc. Final pass, where QuaC-Watch results are also aggregated. Sample: {wildcards.sample}"
    params:
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
        outfilename=lambda wildcards, output: str(Path(output[0]).name),
        in_dirs=lambda wildcards, input: set(str(Path(fp).parent) for fp in input),
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file, if needed
        extra_config=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}" if ALLOW_SAMPLE_RENAMING else f"--config {input.multiqc_config}",
    singularity:
        "docker://quay.io/biocontainers/multiqc:1.9--py_1"
    shell:
        r"""
        multiqc \
            {params.extra_config} \
            --force \
            --outdir {params.outdir} \
            --filename {params.outfilename} \
            {params.in_dirs}
        """



##########################   Multi-sample QC aggregation  ##########################
rule aggregate_sample_rename_configs:
    input:
        expand(
            PROJECT_PATH / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
            sample=SAMPLES,
        ),
    output:
        outfile=protected(OUT_DIR / "project_level_qc" / "multiqc" / "configs" / "aggregated_rename_configs.tsv"),
        tempfile=temp(OUT_DIR / "project_level_qc" / "multiqc" / "configs" / "flist.txt"),
    message:
        "Aggregate all sample rename-config files."
    singularity:
        "docker://quay.io/biocontainers/mulled-v2-78a02249d8cc4e85718933e89cf41d0e6686ac25:70df245247aac9844ee84a9da1e96322a24c1f34-0"
    shell:
        r"""
        # save files in a tempfile
        echo {input} \
            | tr " " "\n" \
            > {output.tempfile}

        python src/aggregate_sample_rename_configs.py \
            --infile {output.tempfile} \
            --outfile {output.outfile}
        """


rule multiqc_aggregation_all_samples:
    input:
        expand(
            [
                PROJECT_PATH / "{sample}" / "qc" / "fastqc-raw" / "{sample}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{sample}" / "qc" / "fastqc-trimmed" / "{sample}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{sample}" / "qc" / "fastq_screen-trimmed" / "{sample}-{unit}-{read}_screen.txt",
                PROJECT_PATH / "{sample}" / "qc" / "dedup" / "{sample}-{unit}.metrics.txt",
            ],
            sample=SAMPLES,
            unit=[1],
            read=["R1", "R2"],
        ) if INCLUDE_PRIOR_QC_DATA else [],
        expand(
            [
                OUT_DIR / "project_level_qc" / "somalier" / "relatedness" / "somalier.html",
                OUT_DIR / "project_level_qc" / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
                OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
                OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
                OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
                OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
                OUT_DIR / "{sample}" / "qc" / "quac_watch" / "quac_watch_overall_summary.yaml",
            ],
            sample=SAMPLES,
            unit=[1],
            read=["R1", "R2"],
        ),
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=OUT_DIR / "project_level_qc" / "multiqc" / "configs" / "aggregated_rename_configs.tsv" if ALLOW_SAMPLE_RENAMING else [],
    output:
        protected(OUT_DIR / "project_level_qc" / "multiqc" / "multiqc_report.html"),
    message:
        "Running multiqc for all samples"
    params:
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
        outfilename=lambda wildcards, output: str(Path(output[0]).name),
        in_dirs=lambda wildcards, input: set(Path(fp).parent for fp in input),
        # multiqc uses fastq's filenames to identify sample names. Rename them to in-house names,
        # using custom rename config file, if needed
        extra_config=(
            lambda wildcards, input: f'--config {input.multiqc_config} \
                                            --sample-names {input.rename_config} \
                                            --cl_config "max_table_rows: 2000"' \
                                            if ALLOW_SAMPLE_RENAMING else \
                                                f'--config {input.multiqc_config} \
                                                --cl_config "max_table_rows: 2000"'
        ),
    singularity:
        "docker://quay.io/biocontainers/multiqc:1.9--py_1"
    shell:
        r"""
        multiqc \
            {params.extra_config} \
            --force \
            --outdir {params.outdir} \
            --filename {params.outfilename} \
            {params.in_dirs}
        """
