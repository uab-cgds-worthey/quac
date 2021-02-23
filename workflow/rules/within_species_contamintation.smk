rule verifybamid:
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
        svd_prefix = lambda wildcards, input: input['svd'][0].replace(Path(input['svd'][0]).suffix, ''),
        out_prefix = lambda wildcards, output: output['ancestry'].replace('.Ancestry', ''),
    shell:
        r"""
        verifybamid2 \
            --SVDPrefix {params.svd_prefix} \
            --Reference {input.ref_genome} \
            --BamFile {input.bam} \
            --Output {params.out_prefix} \
            > {log} 2>&1
        """


rule haplocheck:
    input:
        bam = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        mt_ref = config['haplocheck']['mt_ref'],
        mutserve = config['haplocheck']['mutserve_tool'],
        haplocheck = config['haplocheck']['haplocheck_tool'],
    output:
        vcf = PROCESSED_DIR / "haplocheck/{project}/{sample}/MT.vcf",
        result = PROCESSED_DIR / "haplocheck/{project}/{sample}/haplocheck.txt",
    log:
        LOGS_PATH / "{project}/haplocheck-{sample}.log"
    message:
        "Running haplocheck to detect within-species contamination. Project: {wildcards.project}, sample: {wildcards.sample}"
    shell:
        r"""
        # call MT variants from bam using mutserve
        {input.mutserve} call \
            --reference {input.mt_ref} \
            --contig-name chrM \
            --output {output.vcf} \
            {input.bam}
            > {log} 2>&1

        # run haplocheck
        {input.haplocheck} \
            --raw \
            --out {output.result} \
            {output.vcf}
            >> {log} 2>&1
        """
