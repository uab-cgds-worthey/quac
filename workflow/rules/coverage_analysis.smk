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
        dist = PROCESSED_DIR / "mosdepth/{project}/results/{sample}.mosdepth.global.dist.txt",
        summary = PROCESSED_DIR / "mosdepth/{project}/results/{sample}.mosdepth.summary.txt",
    message:
        "Running mosdepth for coverage. Project: {wildcards.project}, sample: {wildcards.sample}"
    group:
        "mosdepth"
    conda:
        str(WORKFLOW_PATH / "configs/env/mosdepth.yaml")
    threads:
        4
    params:
        out_prefix = lambda wildcards, output: output['summary'].replace('.mosdepth.summary.txt', ''),
    shell:
        r"""
        mosdepth \
            --no-per-base \
            --threads {threads} \
            --fast-mode \
            {params.out_prefix} \
            {input.bam}
        """


rule mosdepth_plot:
    input:
        dist = expand(str(PROCESSED_DIR / "mosdepth" / "{{project}}" / "results" / "{sample}.mosdepth.global.dist.txt"),
                sample=SAMPLES),
        script = WORKFLOW_PATH / "src/mosdepth/v0.3.1/plot-dist.py",
    output:
        PROCESSED_DIR / "mosdepth/{project}/mosdepth_{project}.html",
    message:
        "Running mosdepth plotting. Project: {wildcards.project}"
    group:
        "mosdepth"
    params:
        in_dir = lambda wildcards, input: Path(input[0]).parent,
        workflow_dir = Path(workflow.basedir).parent
    shell:
        r"""
        echo "Heads up: Mosdepth-plotting is run on all samples in "{params.in_dir}"; Not just the files mentioned in the rule's input."

        cd {params.in_dir}  # if not in directory, mosdepth uses filepath as sample name :(
        python {input.script} \
            --output {params.workflow_dir}/{output} \
            *.mosdepth.global.dist.txt
        """


##########################   indexcov   ##########################
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
            {params.project_dir}/[LU][WD]*/bam/*.bam
        """


##########################   covviz   ##########################
rule covviz:
    input:
        bed = PROCESSED_DIR / "indexcov/{project}/{project}-indexcov.bed.gz",
        ped = RAW_DIR / "ped" / "{project}.ped",
    output:
        PROCESSED_DIR / "covviz/{project}/covviz_report.html",
    message:
        "Running covviz. Project: {wildcards.project}"
    conda:
        str(WORKFLOW_PATH / "configs/env/covviz.yaml")
    shell:
        r"""
        covviz \
            --ped {input.ped} \
            --output {output} \
            {input.bed}
        """
