##########################   Samtools   ##########################
rule samtools_stats:
    input:
        PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt"),
    message:
        "stats bam using samtools. Sample: {wildcards.sample}"
    wrapper:
        "0.64.0/bio/samtools/stats"


##########################   Qualimap   ##########################
rule qualimap_bamqc:
    input:
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        target_regions=get_capture_regions_bed,
    output:
        html_report=protected(OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html"),
        coverage=protected(OUT_DIR / "{sample}" / "qc/qualimap/{sample}/raw_data_qualimapReport/coverage_across_reference.txt"),
        summary=protected(OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "genome_results.txt"),
    message:
        "stats bam using qualimap. Sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/qualimap.yaml")
    threads: 2
    params:
        outdir=lambda wildcards, output: str(Path(output["html_report"]).parent),
        capture_bed=lambda wildcards, input: f"--feature-file {input.target_regions}" if input.target_regions else "",
        java_mem="24G",
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
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        ref=config["ref"],
    output:
        multiext(
            str(OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}"),
            ".alignment_summary_metrics",
            ".quality_yield_metrics",
        ),
    message:
        "stats bam using Picard's collectmultiplemetrics. Sample: {wildcards.sample}"
    params:
        "PROGRAM=null ",
    wrapper:
        "0.73.0/bio/picard/collectmultiplemetrics"


rule picard_collect_wgs_metrics:
    input:
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        ref=config["ref"],
    output:
        OUT_DIR / "{sample}" / "qc" / "picard-stats" / "{sample}.collect_wgs_metrics",
    message:
        "stats bam using Picard-CollectMultipleMetrics. Sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/picard.yaml")
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
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        target_regions=get_capture_regions_bed,
    output:
        dist=protected(OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt"),
        summary=protected(OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.summary.txt"),
    message:
        "Running mosdepth for coverage. Sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/mosdepth.yaml")
    threads: 4
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
    params:
        infiles=lambda wildcards: str(OUT_DIR / f"{{{','.join(SAMPLES)}}}" / "qc" / "mosdepth" / "*.mosdepth.global.dist.txt"),
    shell:
        r"""
        python {input.script} \
            --output {output} \
            {params.infiles}
        """


##########################   indexcov   ##########################
rule indexcov:
    input:
        bam=expand(
            PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
            sample=SAMPLES,
        ),
        bam_index=expand(
            PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
            sample=SAMPLES,
        ),
    output:
        html=protected(OUT_DIR / "project_level_qc" / "indexcov" / "index.html"),
        bed=protected(OUT_DIR / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz"),
    message:
        "Running indexcov"
    log:
        OUT_DIR / "project_level_qc" / "indexcov" / "stdout.log",
    conda:
        str(WORKFLOW_PATH / "configs/env/goleft.yaml")
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        infiles=lambda wildcards: str(PROJECT_PATH / f"{{{','.join(SAMPLES)}}}" / "bam" / "*.bam"),
    shell:
        r"""
        goleft indexcov \
            --directory {params.outdir} \
            {params.infiles} \
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
    conda:
        str(WORKFLOW_PATH / "configs/env/covviz.yaml")
    shell:
        r"""
        covviz \
            --ped {input.ped} \
            --output {output.html} \
            {input.bed} \
            > {log} 2>&1
        """
