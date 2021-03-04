TARGETS_COVERAGE = [
    # indexcov
    get_targets('indexcov') if {'all', 'indexcov'}.intersection(MODULES_TO_RUN) else [],
    # covviz
    get_targets('covviz') if {'all', 'covviz'}.intersection(MODULES_TO_RUN) else [],
    # mosdepth
    get_targets('mosdepth') if {'all', 'mosdepth'}.intersection(MODULES_TO_RUN) else [],
]


##########################   Mosdepth   ##########################
rule mosdepth_coverage:
    input:
        bam = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
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
        PROCESSED_DIR / "mosdepth/{project}/mosdepth_{project}.html",
    log:
        LOGS_PATH / "{project}/mosdepth_plot.log"
    message:
        "Running mosdepth plotting. Project: {wildcards.project}"
    params:
        in_dir = lambda wildcards, input: Path(input[0]).parent,
        workflow_dir = Path(workflow.basedir).parent
    shell:
        r"""
        echo "Heads up: Mosdepth-plotting is run on all samples in "{params.in_dir}"; Not just the files mentioned in the rule's input."

        cd {params.in_dir}  # if not in directory, mosdepth uses filepath as sample name :(
        python {input.script} \
            --output {params.workflow_dir}/{output} \
            *.mosdepth.global.dist.txt \
            > {params.workflow_dir}/{log} 2>&1
        """


##########################   indexcov   ##########################
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


##########################   covviz   ##########################
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
