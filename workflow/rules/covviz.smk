rule covviz:
    input:
        PROCESSED_DIR / "indexcov/{project}/{project}-indexcov.bed.gz",
    output:
        PROCESSED_DIR / "covviz/{project}/covviz_report.html",
    log:
        LOGS_PATH / "{project}/covviz.log"
    message:
        "Running covviz. Project: {wildcards.project}"
    conda:
        str(WORKFLOW_PATH / "configs/env/covviz.yaml")
    # params:
    #     outdir = lambda wildcards, output: Path(output[0]).parent,
    shell:
        r"""
        covviz \
            --output {output} \
            {input}
        """
