TARGETS_CONTAMINATION = [
    get_targets('verifybamid') if {'all', 'verifybamid'}.intersection(MODULES_TO_RUN) else [],
]


rule verifybamid:
    input:
        bam = PROJECTS_PATH / PROJECT_NAME / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index = PROJECTS_PATH / PROJECT_NAME / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        ref_genome = config['ref'],
        svd = expand(f"{config['verifyBamID']['svd_dat']}.{{ext}}",
                    ext=['bed', 'mu', 'UD'])
    output:
        ancestry = OUT_DIR / "verifyBamID/{sample}.Ancestry",
        selfsm = OUT_DIR / "verifyBamID/{sample}.selfSM",
    message:
        "Running VerifyBamID to detect within-species contamination. sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/verifyBamID.yaml")
    params:
        svd_prefix = lambda wildcards, input: input['svd'][0].replace(Path(input['svd'][0]).suffix, ''),
        out_prefix = lambda wildcards, output: output['ancestry'].replace('.Ancestry', ''),
    threads:
        4
    shell:
        r"""
        verifybamid2 \
            --NumThread {threads} \
            --SVDPrefix {params.svd_prefix} \
            --Reference {input.ref_genome} \
            --BamFile {input.bam} \
            --Output {params.out_prefix}
        """
