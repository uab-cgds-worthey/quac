##########################   Samtools   ##########################
rule samtools_stats:
    input:
        PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
    output:
        OUT_DIR / "{sample}" / "qc" / "samtools-stats" / "{sample}.txt",
    wrapper:
        "0.64.0/bio/samtools/stats"


##########################   Qualimap   ##########################
rule qualimap_bamqc:
    input:
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        target_regions=get_capture_regions_bed,
    output:
        html_report=OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "qualimapReport.html",
        coverage=OUT_DIR / "{sample}" / "qc/qualimap/{sample}/raw_data_qualimapReport/coverage_across_reference.txt",
        summary=OUT_DIR / "{sample}" / "qc" / "qualimap" / "{sample}" / "genome_results.txt",
    message:
        "stats bam using qualimap"
    conda:
        str(WORKFLOW_PATH / "configs/env/qualimap.yaml")
    params:
        outdir=lambda wildcards, output: str(Path(output["html_report"]).parent),
        capture_bed=lambda wildcards, input: f"--feature-file {input.target_regions}" if input.target_regions else "",
        java_mem="24G",
    shell:
        r"""
        qualimap bamqc \
            -bam {input.bam} \
            {params.capture_bed} \
            -outdir {params.outdir} \
            -outformat HTML \
            --paint-chromosome-limits \
            --genome-gc-distr HUMAN \
            -nt {threads} \
            --java-mem-size={params.java_mem}
        """


##########################   Mosdepth   ##########################
rule mosdepth_coverage:
    input:
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        target_regions=get_capture_regions_bed,
    output:
        dist=OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt",
        summary=OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.summary.txt",
    message:
        "Running mosdepth for coverage. Sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/mosdepth.yaml")
    threads: 4
    params:
        out_prefix=lambda wildcards, output: output["summary"].replace(".mosdepth.summary.txt", ""),
        capture_bed=lambda wildcards, input: f"--by {input.target_regions}" if input.target_regions else "",
    shell:
        r"""
        mosdepth \
            --no-per-base \
            --threads {threads} \
            --fast-mode \
            {params.capture_bed} \
            {params.out_prefix} \
            {input.bam}
        """


rule mosdepth_plot:
    input:
        dist=expand(OUT_DIR / "{sample}" / "qc" / "mosdepth" / "{sample}.mosdepth.global.dist.txt", sample=SAMPLES),
        script=WORKFLOW_PATH / "src/mosdepth/v0.3.1/plot-dist.py",
    output:
        OUT_DIR / "project_level_qc" / "mosdepth" / "mosdepth.html",
    message:
        "Running mosdepth plotting"
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
            PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
            sample=SAMPLES,
        ),
        bam_index=expand(
            PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
            sample=SAMPLES,
        ),
    output:
        html=OUT_DIR / "project_level_qc" / "indexcov" / "index.html",
        bed=OUT_DIR / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz",
    message:
        "Running indexcov"
    log:
        OUT_DIR / "project_level_qc" / "indexcov" / "stdout.log",
    conda:
        str(WORKFLOW_PATH / "configs/env/goleft.yaml")
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        project_dir=lambda wildcards, input: str(Path(input["bam"][0]).parents[2]),
    shell:
        r"""
        echo "Heads up: Indexcov is run on all samples in the "project directory"; Not just the files mentioned in the rule's input."

        goleft indexcov \
            --directory {params.outdir} \
            {params.project_dir}/*/bam/*.bam \
            > {log} 2>&1
        """


##########################   covviz   ##########################
rule covviz:
    input:
        bed=OUT_DIR / "project_level_qc" / "indexcov" / "indexcov-indexcov.bed.gz",
        ped=PEDIGREE_FPATH,
    output:
        html=OUT_DIR / "project_level_qc" / "covviz" / "covviz_report.html",
    message:
        "Running covviz"
    log:
        OUT_DIR / "project_level_qc" / "covviz" / "stdout.log",
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
