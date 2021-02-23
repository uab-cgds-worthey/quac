rule mosdepth_coverage:
    input:
        bam = lambda wildcards: expand(str(PROJECTS_PATH / wildcards.project / "analysis" / "{sample}" / "bam" / "{sample}.bam"),
                sample=SAMPLES[wildcards.project]),
        bam_index = lambda wildcards: expand(str(PROJECTS_PATH / wildcards.project / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai"),
                sample=SAMPLES[wildcards.project]),
    output:
        dist = INTERIM_DIR / "mosdepth/{project}/{sample}.mosdepth.global.dist.txt",
        summary = INTERIM_DIR / "mosdepth/{project}/{sample}.mosdepth.summary.txt",
    log:
        LOGS_PATH / "{project}/mosdepth_coverage-{sample}.log"
    message:
        "Running mosdepth for coverage. Project: {wildcards.project}, sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/mosdepth.yaml")
    params:
        out_prefix = lambda wildcards, output: output['summary'].replace('.mosdepth.summary.txt', ''),
    shell:
        r"""
        mosdepth \
            --no-per-base \
            --threads {threads} \
            --fast-mode \
            {params.out_prefix} \
            {input.bam} \
            > {log} 2>&1
        """


rule mosdepth_plot:
    input:
        dist = lambda wildcards: expand(str(INTERIM_DIR / "mosdepth" / wildcards.project / "{sample}.mosdepth.global.dist.txt"),
                sample=SAMPLES[wildcards.project]),
        script = WORKFLOW_PATH / "src/mosdepth/v0.3.1/plot-dist.py",
    output:
        INTERIM_DIR / "mosdepth/{project}/mosdepth_{project}.html",
    log:
        LOGS_PATH / "{project}/mosdepth_plot.log"
    message:
        "Running mosdepth plotting. Project: {wildcards.project}"
    params:
        in_dir = lambda wildcards, input: Path(input[0]).parent,
    shell:
        r"""
        echo "Heads up: Mosdepth-plotting is run on all samples in "{params.in_dir}"; Not just the files mentioned in the rule's input."

        cd {params.in_dir}
        python {input.script} \
            --output {output} \
            *.mosdepth.global.dist.txt
        """
