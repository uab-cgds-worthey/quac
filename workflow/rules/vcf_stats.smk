rule bcftools_stats:
    input:
        PROJECT_PATH / "analysis" / "{sample}" / "vcf" / "{sample}.vcf.gz",
    output:
        OUT_DIR / "analysis" / "{sample}" / "qc" / "bcftools-stats" / "{sample}.bcftools.stats",
    message:
        "stats vcf using bcftools"
    conda:
        str(WORKFLOW_PATH / "configs/env/bcftools.yaml")
    shell:
        r"""
        bcftools stats -s - \
            {input} \
            > {output}
        """
