rule bcftools_stats:
    input:
        PROJECT_PATH / "{sample}" / "vcf" / "{sample}.vcf.gz",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats"),
    message:
        "stats vcf using bcftools"
    conda:
        str(WORKFLOW_PATH / "configs/env/bcftools.yaml")
    shell:
        r"""
        bcftools stats --samples - \
            {input} \
            > {output}
        """


rule bcftools_index:
    input:
        PROJECT_PATH / "{sample}" / "vcf" / "{sample}.vcf.gz",
    output:
        protected(OUT_DIR / "{sample}" / "qc" / "bcftools-index" / "{sample}.bcftools.index.tsv"),
    message:
        "Obtains per-contig variant count stats using bcftools index"
    conda:
        str(WORKFLOW_PATH / "configs/env/bcftools.yaml")
    shell:
        r"""
        bcftools index --stats \
            {input} \
            > {output}
        """
