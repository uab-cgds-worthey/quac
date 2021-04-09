rule somalier_extract:
    input:
        bam=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "{sample}" / "bam" / "{sample}.bam.bai",
        sites=config["somalier"]["sites"],
        ref_genome=config["ref"],
    output:
        OUT_DIR / "project_level_qc" / "somalier" / "extract" / "{sample}.somalier",
    message:
        "Running somalier extract. Sample: {wildcards.sample}"
    singularity:
        "docker://brentp/somalier:v0.2.12"
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        sample_name="{sample}",
    shell:
        r"""
        somalier extract \
            --sites {input.sites} \
            --fasta {input.ref_genome} \
            --out-dir {params.outdir} \
            --sample-prefix {params.sample_name} \
            {input.bam}
        """


rule somalier_relate:
    input:
        extracted=expand(OUT_DIR / "project_level_qc" / "somalier" / "extract" / "{sample}.somalier", sample=SAMPLES),
        ped=PEDIGREE_FPATH,
    output:
        out=expand(
            OUT_DIR / "project_level_qc" / "somalier" / "relatedness" / "somalier.{ext}",
            ext=["html", "pairs.tsv", "samples.tsv"],
        ),
    message:
        "Running somalier relate"
    singularity:
        "docker://brentp/somalier:v0.2.12"
    log:
        log=OUT_DIR / "project_level_qc" / "somalier" / "relatedness" / "somalier.log",
    params:
        outdir=lambda wildcards, output: Path(output["out"][0]).parent,
        infiles=lambda wildcards: str(OUT_DIR / "project_level_qc" / "somalier" / "extract" / f"{{{','.join(SAMPLES)}}}.somalier")
    shell:
        r"""
        echo "Heads up: Somalier is run on all samples in the input directory; Not just the files mentioned in the rule's input."

        somalier relate \
            --ped {input.ped} \
            --infer \
            --output-prefix {params.outdir}/somalier \
            {params.infiles} \
            > {log} 2>&1
        """


rule somalier_ancestry:
    input:
        extracted=expand(OUT_DIR / "project_level_qc" / "somalier" / "extract" / "{sample}.somalier", sample=SAMPLES),
        labels_1kg=config["somalier"]["labels_1kg"],
        somalier_1kg=directory(config["somalier"]["somalier_1kg"]),
    output:
        out=expand(
            OUT_DIR / "project_level_qc" / "somalier" / "ancestry" / "somalier.somalier-ancestry.{ext}",
            ext=["html", "tsv"],
        ),
    message:
        "Running somalier ancestry."
    singularity:
        "docker://brentp/somalier:v0.2.12"
    log:
        log=OUT_DIR / "project_level_qc" / "somalier" / "ancestry" / "somalier.log",
    params:
        outdir=lambda wildcards, output: Path(output["out"][0]).parent,
        infiles=lambda wildcards: str(OUT_DIR / "project_level_qc" / "somalier" / "extract" / f"{{{','.join(SAMPLES)}}}.somalier")
    shell:
        r"""
        somalier ancestry \
            --output-prefix {params.outdir}/somalier \
            --labels {input.labels_1kg} \
            {input.somalier_1kg}/*.somalier ++ \
            {params.infiles} \
            > {log} 2>&1
        """
