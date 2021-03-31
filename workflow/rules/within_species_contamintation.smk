TARGETS_CONTAMINATION = [
    get_targets("verifybamid", SAMPLES) if {"all", "verifybamid"}.intersection(MODULES_TO_RUN) else [],
]


def get_svd(wildcards):
    if EXOME_MODE:
        return expand(f"{config['verifyBamID']['svd_dat_exome']}.{{ext}}", ext=["bed", "mu", "UD"])
    else:
        return expand(f"{config['verifyBamID']['svd_dat_wgs']}.{{ext}}", ext=["bed", "mu", "UD"])


rule verifybamid:
    input:
        bam=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        ref_genome=config["ref"],
        svd=get_svd,
    output:
        ancestry=OUT_DIR / "verifyBamID/{sample}.Ancestry",
        selfsm=OUT_DIR / "verifyBamID/{sample}.selfSM",
    message:
        "Running VerifyBamID to detect within-species contamination. sample: {wildcards.sample}"
    conda:
        str(WORKFLOW_PATH / "configs/env/verifyBamID.yaml")
    params:
        svd_prefix=lambda wildcards, input: input["svd"][0].replace(Path(input["svd"][0]).suffix, ""),
        out_prefix=lambda wildcards, output: output["ancestry"].replace(".Ancestry", ""),
        sanity_check="--DisableSanityCheck" if is_testing_mode() else "",
    threads: 4
    shell:
        r"""
        verifybamid2 {params.sanity_check} \
            --NumThread {threads} \
            --SVDPrefix {params.svd_prefix} \
            --Reference {input.ref_genome} \
            --BamFile {input.bam} \
            --Output {params.out_prefix}
        """
