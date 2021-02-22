rule run_verifybamid:
    input:
        bam = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        ref_genome = config['ref'],
        svd = expand(f"{config['verifyBamID']['svd_dat']}.{{ext}}",
                    ext=['bed', 'mu', 'UD'])
    output:
        ancestry = PROCESSED_DIR / "verifyBamID/{project}/{sample}.Ancestry",
        selfsm = PROCESSED_DIR / "verifyBamID/{project}/{sample}.selfSM",
    log:
        LOGS_PATH / "{project}/verifyBamID-{sample}.log"
    message:
        "Running VerifyBamID to detect within-species contamination. Project: {wildcards.project}, sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/verifyBamID.yaml")
    params:
        out_prefix = lambda wildcards, output: output['ancestry'].replace('.Ancestry', ''),
    shell:
        r"""
        verifybamid2 \
            --SVDPrefix {input.svd} \
            --Reference {input.ref_genome} \
            --BamFile {input.bam} \
            --Output {params.out_prefix} \
            2>&1 {log}
        """
