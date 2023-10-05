rule bcftools_stats:
    input:
        lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["vcf"],
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats"),
    message:
        "stats vcf using bcftools. Sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/bcftools:1.12--h45bccc9_1"
    shell:
        r"""
        bcftools stats --samples - \
            {input} \
            > {output}
        """


rule bcftools_index:
    input:
        lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["vcf"],
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "bcftools-index" / "{sample}.bcftools.index.tsv"),
    message:
        "Obtains per-contig variant count stats using bcftools index. Sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/bcftools:1.12--h45bccc9_1"
    shell:
        r"""
        bcftools index --stats \
            {input} \
            > {output}
        """
