##########################     Create Multiqc config file    ##########################
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
        lambda wildcards: expand(OUT_DIR / wildcards.sample / "qc" / "fastqc-raw" / f"{wildcards.sample}-{{unit}}-{{reads}}_fastqc.html", 
                unit=SAMPLES_CONFIG[wildcards.sample]["fastq"].keys(), 
                reads=["R1", "R2"]),
        lambda wildcards: expand(OUT_DIR / wildcards.sample / "qc" / "fastq_screen-raw" / f"{wildcards.sample}-{{unit}}-{{reads}}_screen.txt", 
                unit=SAMPLES_CONFIG[wildcards.sample]["fastq"].keys(), 
                reads=["R1", "R2"]),
        lambda wildcards: get_priorQC_filepaths(wildcards.sample, SAMPLES_CONFIG) if INCLUDE_PRIOR_QC_DATA else [],
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc.html"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_general_stats.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc.txt"),
        protected(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt"),
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
        extra_config=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}",
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
        fastqc=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastqc.txt",
        fastq_screen=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "{sample}_multiqc_data" / "multiqc_fastq_screen.txt",
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
                    "fastqc", 
                    "fastq_screen",
                ],
            )
        ),
        protected(
            expand(
                OUT_DIR / "{{sample}}" / "qc" / "quac_watch" / "quac_watch_{suffix}.yaml",
                suffix=["picard_dups"],
            )
        ) if INCLUDE_PRIOR_QC_DATA else [],
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Runs QuaC-Watch on various QC tool output, based on custom defined QC thresholds. "
        "Note that this will NOT work as expected for multi-sample analysis. Sample: {wildcards.sample}"
    params:
        sample="{sample}",
        outdir=lambda wildcards, output: str(Path(output[0]).parent),
        extra=lambda wildcards, input: f'--picard_dups "{input.picard_dups}"' if INCLUDE_PRIOR_QC_DATA else "",
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
            --fastqc "{input.fastqc}" \
            --fastq_screen "{input.fastq_screen}" \
            {params.extra} \
            --sample {params.sample} \
            --outdir {params.outdir}
        """


rule multiqc_by_sample_final_pass:
    input:
        lambda wildcards: expand(OUT_DIR / wildcards.sample / "qc" / "fastqc-raw" / f"{wildcards.sample}-{{unit}}-{{reads}}_fastqc.html", 
                unit=SAMPLES_CONFIG[wildcards.sample]["fastq"].keys(), 
                reads=["R1", "R2"]),
        lambda wildcards: expand(OUT_DIR / wildcards.sample / "qc" / "fastq_screen-raw" / f"{wildcards.sample}-{{unit}}-{{reads}}_screen.txt", 
                unit=SAMPLES_CONFIG[wildcards.sample]["fastq"].keys(), 
                reads=["R1", "R2"]),
        lambda wildcards: get_priorQC_filepaths(wildcards.sample, SAMPLES_CONFIG) if INCLUDE_PRIOR_QC_DATA else [],
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
        OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
        OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
        OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
        OUT_DIR / "{sample}" / "qc" / "quac_watch" / "quac_watch_overall_summary.yaml",
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
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
        extra_config=lambda wildcards, input: f"--config {input.multiqc_config} --sample-names {input.rename_config}",
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
        expand(OUT_DIR / "{sample}" / "qc" / "multiqc_initial_pass" / "multiqc_sample_rename_config" / "{sample}_rename_config.tsv",
            sample=SAMPLES)
    output:
        outfile=protected(OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "multiqc" / "configs" / "aggregated_rename_configs.tsv"),
        tempfile=temp(OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "multiqc" / "configs" / "flist.txt"),
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
        [get_priorQC_filepaths(sample, SAMPLES_CONFIG) for sample in SAMPLES_CONFIG.keys()] if INCLUDE_PRIOR_QC_DATA else [],
        [OUT_DIR / sample / "qc" / "fastqc-raw" / f"{sample}-{unit}-{read}_fastqc.html" 
            for sample in SAMPLES_CONFIG 
            for unit in SAMPLES_CONFIG[sample]["fastq"].keys()
            for read in ["R1", "R2"]
            ],
        [OUT_DIR / sample / "qc" / "fastq_screen-raw" / f"{sample}-{unit}-{read}_screen.txt" 
            for sample in SAMPLES_CONFIG 
            for unit in SAMPLES_CONFIG[sample]["fastq"].keys()
            for read in ["R1", "R2"]
            ],
        expand(
            [
                OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "somalier" / "relatedness" / "somalier.html",
                OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
                OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
                OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.alignment_summary_metrics",
                OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
                OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry",
                OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
                OUT_DIR / "{sample}" / "qc" / "quac_watch" / "quac_watch_overall_summary.yaml",
            ],
            sample=SAMPLES,
        ),
        multiqc_config=MULTIQC_CONFIG_FILE,
        rename_config=OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "multiqc" / "configs" / "aggregated_rename_configs.tsv",
    output:
        protected(OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "multiqc" / "multiqc_report.html"),
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
