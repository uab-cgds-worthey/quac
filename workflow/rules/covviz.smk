rule covviz:
    input:
        bed = PROCESSED_DIR / "indexcov/{project}/{project}-indexcov.bed.gz",
        ped = RAW_DIR / "ped" / "{project}.ped",
    output:
        PROCESSED_DIR / "covviz/{project}/covviz_report.html",
    log:
        LOGS_PATH / "{project}/covviz.log"
    message:
        "Running covviz. Project: {wildcards.project}"
    conda:
        str(WORKFLOW_PATH / "configs/env/covviz.yaml")
    shell:
        r"""
        covviz \
            --ped {input.ped} \
            --output {output} \
            {input.bed} \
            > {log} 2>&1
        """
