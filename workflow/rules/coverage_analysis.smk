##########################   Samtools   ##########################
rule samtools_stats:
    input:
        lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"]
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt"),
    singularity:
        "docker://quay.io/biocontainers/samtools:1.10--h2e538c0_3"
    message:
        "stats bam using samtools. Sample: {wildcards.sample}"
    shell:
        r"""
        samtools stats \
            {input} \
            > {output}
        """


##########################   Qualimap   ##########################
rule qualimap_bamqc:
    input:
        bam=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"],
        bam_index=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"] + ".bai",
        target_regions=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["capture_bed"] if EXOME_MODE else [],
    output:
        html_report=protected(OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html"),
        coverage=protected(OUT_DIR / "{sample}" / "qc/qualimap/{sample}/raw_data_qualimapReport/coverage_across_reference.txt"),
        summary=protected(OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "genome_results.txt"),
    message:
        "stats bam using qualimap. Sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/qualimap:2.2.2d--hdfd78af_2"
    threads: config["resources"]["qualimap_bamqc"]["no_cpu"]
    params:
        outdir=lambda wildcards, output: str(Path(output["html_report"]).parent),
        capture_bed=lambda wildcards, input: f"--feature-file {input.target_regions}" if input.target_regions else "",
        java_mem=config["resources"]["qualimap_bamqc"]["mem_per_cpu"],
    shell:
        r"""
        unset DISPLAY
        qualimap bamqc \
            -bam {input.bam} \
            {params.capture_bed} \
            -outdir {params.outdir} \
            -outformat HTML \
            --paint-chromosome-limits \
            --genome-gc-distr HUMAN \
            -nt {threads} \
            --java-mem-size={params.java_mem}
        """


##########################   Picard   ##########################
rule picard_collect_multiple_metrics:
    input:
        bam=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"],
        bam_index=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"] + ".bai",
        ref=config["datasets"]["ref"],
    output:
        multiext(
            str(OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}"),
            ".alignment_summary_metrics",
            ".quality_yield_metrics",
        ),
    singularity:
        "docker://quay.io/biocontainers/picard:2.23.0--0"
    message:
        "Stats bam using Picard's collectmultiplemetrics. Sample: {wildcards.sample}"
    params:
        out_prefix=lambda wildcards, output: str(Path(output[0]).with_suffix('')),
    shell:
        r"""
        picard CollectMultipleMetrics \
            I={input.bam} \
            O={params.out_prefix} \
            R={input.ref} \
            PROGRAM=null \
            PROGRAM=CollectAlignmentSummaryMetrics \
            PROGRAM=CollectQualityYieldMetrics
        """


rule picard_collect_wgs_metrics:
    input:
        bam=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"],
        bam_index=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"] + ".bai",
        ref=config["datasets"]["ref"],
    output:
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
    message:
        "Stats bam using Picard-CollectWgsMetrics. Sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/picard:2.23.0--0"
    shell:
        r"""
        picard CollectWgsMetrics \
            I={input.bam} \
            O={output} \
            R={input.ref}
        """


##########################   Mosdepth   ##########################
rule mosdepth_coverage:
    input:
        bam=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"],
        bam_index=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"] + ".bai",
        target_regions=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["capture_bed"] if EXOME_MODE else [],
    output:
        dist=protected(OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt"),
        summary=protected(OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.summary.txt"),
    message:
        "Running mosdepth for coverage. Sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/mosdepth:0.3.1--h01d7912_2"
    threads: config["resources"]["mosdepth_coverage"]["no_cpu"]
    params:
        out_prefix=lambda wildcards, output: output["summary"].replace(".mosdepth.summary.txt", ""),
        capture_bed=lambda wildcards, input: f"--by {input.target_regions}" if input.target_regions else "",
    shell:
        r"""
        mosdepth \
            --no-per-base \
            --threads {threads} \
            --fast-mode \
            {params.capture_bed} \
            {params.out_prefix} \
            {input.bam}
        """


rule mosdepth_plot:
    input:
        dist=expand(
            OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt",
            sample=SAMPLES,
        ),
        script=WORKFLOW_PATH / "src/mosdepth/v0.3.1/plot-dist.py",
    output:
        protected(OUT_DIR / "project_level_qc" / "mosdepth" / "mosdepth.html"),
    message:
        "Running mosdepth plotting"
    singularity: 
        "docker://continuumio/miniconda3:4.7.12"
    shell:
        r"""
        python {input.script} \
            --output {output} \
            {input.dist}
        """


##########################   indexcov   ##########################
rule indexcov:
    input:
        bam=[value["bam"] for value in SAMPLES_CONFIG.values()],
        bam_index=[value["bam"]+".bai" for value in SAMPLES_CONFIG.values()],
    output:
        html=protected(OUT_DIR / "project_level_qc" / "indexcov" / "index.html"),
        bed=protected(OUT_DIR / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz"),
    message:
        "Running indexcov"
    log:
        OUT_DIR / "project_level_qc" / "indexcov" / "stdout.log",
    singularity:
        "docker://quay.io/biocontainers/goleft:0.2.4--0"
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
    shell:
        r"""
        goleft indexcov \
            --directory {params.outdir} \
            {input.bam} \
            > {log} 2>&1
        """


##########################   covviz   ##########################
rule covviz:
    input:
        bed=OUT_DIR / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz",
        ped=PEDIGREE_FPATH,
    output:
        html=protected(OUT_DIR / "project_level_qc" / "covviz" / "covviz_report.html"),
    message:
        "Running covviz"
    log:
        OUT_DIR / "project_level_qc" / "covviz" / "stdout.log",
    singularity:
        "docker://brwnj/covviz:v1.2.2"
    shell:
        r"""
        covviz \
            --ped {input.ped} \
            --output {output.html} \
            {input.bed} \
            > {log} 2>&1
        """
