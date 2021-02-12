rule mosdepth:
    input:
        bam = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
    output:
        dist = INTERIM_DIR / "mosdepth/{project}/{sample}.mosdepth.global.dist.txt",
        summary = INTERIM_DIR / "mosdepth/{project}/{sample}.mosdepth.summary.txt",
    log:
        LOGS_PATH / "{project}/mosdepth-{sample}.log"
    message:
        "Running somalier. Project: {wildcards.project}, sample: {wildcards.sample}"
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
            2>&1 {log}
        """
