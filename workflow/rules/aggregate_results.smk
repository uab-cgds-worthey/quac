rule multiqc:
    input:
        TARGETS_SOMALIER,
        TARGETS_COVERAGE,
        TARGETS_CONTAMINATION,
    output:
        OUT_DIR / "multiqc/multiqc_report.html",
    message:
        "Aggregates QC results using multiqc."
    conda:
        str(WORKFLOW_PATH / "configs/env/multiqc.yaml")
    params:
        out_dir=lambda wildcards, output: str(Path(output[0]).parent),
        in_dirs=OUT_DIR,
    shell:
        r"""
        unset PYTHONPATH
        multiqc \
            --cl_config "max_table_rows: 2000" \
            --force \
            -o "{params.out_dir}" \
            {params.in_dirs}
        """
