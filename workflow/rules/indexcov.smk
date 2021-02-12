rule indexcov:
    input:
        bam = expand(str(PROJECTS_PATH / "{{project}}" / "analysis" / "{sample}" / "bam" / "{sample}.bam"),
                sample=SAMPLES),
        bam_index = expand(str(PROJECTS_PATH / "{{project}}" / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai"),
                sample=SAMPLES),
        goleft_tool = config['goleft']['tool'],
    output:
        PROCESSED_DIR / "indexcov/{project}/index.html",
        PROCESSED_DIR / "indexcov/{project}/{project}-indexcov.bed.gz",
    log:
        LOGS_PATH / "{project}/indexcov.log"
    message:
        "Running indexcov. Project: {wildcards.project}"
    params:
        outdir = lambda wildcards, output: Path(output[0]).parent,
        project_dir = lambda wildcards, input: str(Path(input['bam'][0]).parents[2]),
    shell:
        r"""
        echo "Heads up: Indexcov is run on all samples in the "project directory"; Not just the files mentioned in rule."

        {input.goleft_tool} indexcov \
            --directory {params.outdir} \
            {params.project_dir}/[LU][WD]*/bam/*.bam
        """
