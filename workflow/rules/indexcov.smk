rule indexcov:
    input:
        bam = lambda wildcards: expand(str(PROJECTS_PATH / wildcards.project / "analysis" / "{sample}" / "bam" / "{sample}.bam"),
                sample=SAMPLES[wildcards.project]),
        bam_index = lambda wildcards: expand(str(PROJECTS_PATH / wildcards.project / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai"),
                sample=SAMPLES[wildcards.project]),
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
        echo "Heads up: Indexcov is run on all samples in the "project directory"; Not just the files mentioned in the rule's input."

        {input.goleft_tool} indexcov \
            --directory {params.outdir} \
            {params.project_dir}/[LU][WD]*/bam/*.bam \
            > {log} 2>&1
        """
