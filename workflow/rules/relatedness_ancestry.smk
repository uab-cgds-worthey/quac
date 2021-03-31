TARGETS_SOMALIER = [
    get_targets("somalier") if {"all", "somalier"}.intersection(MODULES_TO_RUN) else [],
]


rule somalier_extract:
    input:
        bam=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam",
        bam_index=PROJECT_PATH / "analysis" / "{sample}" / "bam" / "{sample}.bam.bai",
        somalier_tool=config["somalier"]["tool"],
        sites=config["somalier"]["sites"],
        ref_genome=config["ref"],
    output:
        OUT_DIR / "somalier/extract/{sample}.somalier",
    message:
        "Running somalier extract. Sample: {wildcards.sample}"
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
        sample_name="{sample}",
    shell:
        r"""
        {input.somalier_tool} extract \
            --sites {input.sites} \
            --fasta {input.ref_genome} \
            --out-dir {params.outdir} \
            --sample-prefix {params.sample_name} \
            {input.bam}
        """


rule somalier_relate:
    input:
        extracted=expand(
            str(OUT_DIR / "somalier" / "extract" / "{sample}.somalier"), sample=SAMPLES
        ),
        ped=PEDIGREE_FPATH,
        somalier_tool=config["somalier"]["tool"],
    output:
        out=expand(
            str(OUT_DIR / "somalier" / "relatedness" / "somalier.{ext}"),
            ext=["html", "pairs.tsv", "samples.tsv"],
        ),
    message:
        "Running somalier relate"
    log:
        log=OUT_DIR / "somalier" / "relatedness" / "somalier.log",
    params:
        outdir=lambda wildcards, output: Path(output["out"][0]).parent,
        indir=lambda wildcards, input: Path(input[0]).parent,
    shell:
        r"""
        echo "Heads up: Somalier is run on all samples in the input directory; Not just the files mentioned in the rule's input."

        {input.somalier_tool} relate \
            --ped {input.ped} \
            --infer \
            --output-prefix {params.outdir}/somalier \
            {params.indir}/*.somalier \
            > {log} 2>&1
        """


rule somalier_ancestry:
    input:
        extracted=expand(
            str(OUT_DIR / "somalier" / "extract" / "{sample}.somalier"), sample=SAMPLES
        ),
        somalier_tool=config["somalier"]["tool"],
        labels_1kg=config["somalier"]["labels_1kg"],
        somalier_1kg=directory(config["somalier"]["somalier_1kg"]),
    output:
        out=expand(
            str(OUT_DIR / "somalier" / "ancestry" / "somalier.somalier-ancestry.{ext}"),
            ext=["html", "tsv"],
        ),
    message:
        "Running somalier ancestry."
    log:
        log=OUT_DIR / "somalier" / "ancestry" / "somalier.log",
    params:
        outdir=lambda wildcards, output: Path(output["out"][0]).parent,
        indir=lambda wildcards, input: Path(input[0]).parent,
    shell:
        r"""
        echo "Heads up: Somalier is run on all samples in the input directory; Not just the files mentioned in the rule's input."

        {input.somalier_tool} ancestry \
            --output-prefix {params.outdir}/somalier \
            --labels {input.labels_1kg} \
            {input.somalier_1kg}/*.somalier ++ \
            {params.indir}/*.somalier \
            > {log} 2>&1
        """
