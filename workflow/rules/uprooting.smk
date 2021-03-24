rule samtools_stats:
    input:
        PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam",
    output:
        OUT_DIR / "samtools-stats" / "{sample}.txt"",
        # protected(PROJECT_PATH + "/{sample}/qc/samtools-stats/{sample}.txt"),
    wrapper:
        "0.64.0/bio/samtools/stats"


rule qualimap_bamqc:
    input:
        bam = PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        index = PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        #TODO: target regions
        # target_regions = config["processing"]["restrict-regions"] if config["processing"].get("restrict-regions") else []
        target_regions = []
    output:
        html_report = OUT_DIR / "qualimap" / "{sample}" / "qualimapReport.html",
        coverage = OUT_DIR / "qualimap" / "{sample}" / "raw_data_qualimapReport" / "coverage_across_reference.txt",
        summary = OUT_DIR / "qualimap" / "{sample}" / "genome_results.txt",
    message:
        "stats bam using qualimap"
    conda:
        "../envs/qualimap.yaml"
    params:
        outdir = lambda wildcards, output: str(Path(output['html_report']).parent),
        capture_bed = lambda wildcards, input: f"--feature-file {input.target_regions}" if input.target_regions else '',
        java_mem="24G"
    shell:
        r"""
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


rule bcftools_stats:
    input:
        PROJECT_PATH / "analysis" / "{sample}" / "vcf" / "{sample}.vcf.gz",
    output:
        coverage = OUT_DIR / "bcftools-stats" / "{sample}.bcftools.stats",
    message:
        "stats vcf using bcftools"
    conda:
        "../envs/bcftools.yaml"
    shell:
        r"""
        bcftools stats -s - \
            {input} \
            > {output}
        """
