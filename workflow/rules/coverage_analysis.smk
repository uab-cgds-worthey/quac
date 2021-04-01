##########################   Mosdepth   ##########################
rule mosdepth_coverage:
    input:
        bam=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
    output:
        dist=OUT_DIR / "analysis" / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt",
        summary=OUT_DIR / "analysis" / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.summary.txt",
    message:
        "Running mosdepth for coverage. Sample: {wildcards.sample}"
    group:
        "mosdepth"
    conda:
        str(WORKFLOW_PATH / "configs/env/mosdepth.yaml")
    threads: 4
    params:
        out_prefix=lambda wildcards, output: output["summary"].replace(".mosdepth.summary.txt", ""),
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
        dist=expand(
            str(OUT_DIR / "analysis" / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt"), sample=SAMPLES
        ),
        script=WORKFLOW_PATH / "src/mosdepth/v0.3.1/plot-dist.py",
    output:
        OUT_DIR / "analysis" / "project_level_qc" / "mosdepth" / "mosdepth.html"
    message:
        "Running mosdepth plotting"
    group:
        "mosdepth"
    params:
        in_dir=lambda wildcards, input: Path(input[0]).parent,
    shell:
        r"""
        echo "Heads up: Mosdepth-plotting is run on all samples in "{params.in_dir}"; Not just the files mentioned in the rule's input."

        cd {params.in_dir}  # if not in directory, mosdepth uses filepath as sample name :(
        python {input.script} \
            --output {output} \
            *.mosdepth.global.dist.txt
        """


##########################   indexcov   ##########################
rule indexcov:
    input:
        bam=expand(
            str(PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam"),
            sample=SAMPLES,
        ),
        bam_index=expand(
            str(PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai"),
            sample=SAMPLES,
        ),
        goleft_tool=config["goleft"]["tool"],
    output:
        html=OUT_DIR / "analysis" / "project_level_qc" / "indexcov" / "index.html",
        bed=OUT_DIR / "analysis" / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz",
    message:
        "Running indexcov"
    log:
        OUT_DIR / "indexcov" / "stdout.log",
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        project_dir=lambda wildcards, input: str(Path(input["bam"][0]).parents[2]),
    shell:
        r"""
        echo "Heads up: Indexcov is run on all samples in the "project directory"; Not just the files mentioned in the rule's input."

        {input.goleft_tool} indexcov \
            --directory {params.outdir} \
            {params.project_dir}/*/bam/*.bam \
            > {log} 2>&1
        """


##########################   covviz   ##########################
rule covviz:
    input:
        bed=OUT_DIR / "analysis" / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz",
        ped=PEDIGREE_FPATH,
    output:
        html=OUT_DIR / "analysis" / "project_level_qc" / "covviz" / "covviz_report.html",
    message:
        "Running covviz"
    log:
        OUT_DIR / "covviz" / "stdout.log",
    conda:
        str(WORKFLOW_PATH / "configs/env/covviz.yaml")
    shell:
        r"""
        covviz \
            --ped {input.ped} \
            --output {output.html} \
            {input.bed} \
            > {log} 2>&1
        """
