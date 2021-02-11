rule extract:
    input:
        vcf = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "vcf" / "{sample}.vcf.gz",
        vcf_index = PROJECTS_PATH / "{project}" / "analysis" / "{sample}" / "vcf" / "{sample}.vcf.gz.tbi",
        somalier_tool = config['somalier']['tool'],
        sites = config['somalier']['sites'],
        ref_genome = config['somalier']['ref'],
    output:
        INTERIM_DIR / "somalier_extract/{project}/{sample}.somalier"
    message:
        "Running somalier extract. Project: {wildcards.project}"
    params:
        outdir = lambda wildcards, output: Path(output[0]).parent,
    shell:
        r"""
        {input.somalier_tool} extract \
            --sites {input.sites} \
            --fasta {input.ref_genome} \
            --out-dir {params.outdir} \
            {input.vcf}
        """


rule relate:
    input:
        extracted = expand(str(INTERIM_DIR / "somalier_extract/{{project}}/{sample}.somalier"),
                        sample=SAMPLES),
        # ped = RAW_DIR / "ped" / "{project}.ped",
        somalier_tool = config['somalier']['tool'],
    output:
        expand(str(PROCESSED_DIR / "somalier/{{project}}/somalier.{ext}"),
                ext=['html', 'groups.tsv', 'pairs.tsv', 'samples.tsv']),
    message:
        "Running somalier relate. Project: {wildcards.project}"
    params:
        outdir = lambda wildcards, output: Path(output[0]).parent,
    shell:
        r"""
        {input.somalier_tool} relate \
            --infer \
            --output-prefix {params.outdir}/somalier \
            {input.extracted}
        """
            # --ped {input.ped} \


rule ancestry:
    input:
        extracted = expand(str(INTERIM_DIR / "somalier_extract/{{project}}/{sample}.somalier"),
                        sample=SAMPLES),
        somalier_tool = config['somalier']['tool'],
        labels_1kg = config['somalier']['labels_1kg'],
        somalier_1kg = directory(config['somalier']['somalier_1kg']),
    output:
        expand(str(PROCESSED_DIR / "somalier/{{project}}/somalier.somalier-ancestry.{ext}"),
                ext=['html', 'tsv']),
    message:
        "Running somalier ancestry. Project: {wildcards.project}"
    params:
        outdir = lambda wildcards, output: Path(output[0]).parent,
    shell:
        r"""
        {input.somalier_tool} ancestry \
            --output-prefix {params.outdir}/somalier \
            --labels {input.labels_1kg} \
            {input.somalier_1kg}*.somalier ++ \
            {input.extracted}
        """
