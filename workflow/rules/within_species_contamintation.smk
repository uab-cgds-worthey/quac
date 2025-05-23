def get_svd(wildcards):
    if EXOME_MODE:
        return expand(f"{config['datasets']['verifyBamID']['svd_dat_exome']}.{{ext}}", ext=["bed", "mu", "UD"])
    else:
        return expand(f"{config['datasets']['verifyBamID']['svd_dat_wgs']}.{{ext}}", ext=["bed", "mu", "UD"])


rule verifybamid:
    input:
        bam=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"],
        bam_index=lambda wildcards: SAMPLES_CONFIG[wildcards.sample]["bam"] + ".bai",
        ref_genome=config["datasets"]["ref"],
        svd=get_svd,
    output:
        ancestry=protected(OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.Ancestry"),
        selfsm=protected(OUT_DIR / "{sample}" / "qc" / "verifyBamID" / "{sample}.selfSM"),
    message:
        "Running VerifyBamID to detect within-species contamination. sample: {wildcards.sample}"
    singularity:
        "docker://quay.io/biocontainers/verifybamid2:2.0.1--h6a62bbb_9"
    params:
        svd_prefix=lambda wildcards, input: input["svd"][0].replace(Path(input["svd"][0]).suffix, ""),
        out_prefix=lambda wildcards, output: output["ancestry"].replace(".Ancestry", ""),
        sanity_check="--DisableSanityCheck" if is_testing_mode() else "",
    threads: config["resources"]["verifybamid"]["no_cpu"]
    shell:
        r"""
        verifybamid2 {params.sanity_check} \
            --NumThread {threads} \
            --SVDPrefix {params.svd_prefix} \
            --Reference {input.ref_genome} \
            --BamFile {input.bam} \
            --Output {params.out_prefix}
        """
