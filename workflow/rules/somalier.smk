rule extract:
    input:
        # TODO
        vcf = ""
        somalier_tool = config['somalier']['tool'],
        sites = config['somalier']['sites'],
        ref_genome = config['somalier']['ref'],
    output:
        TODO
    # message:
    params:
        outdir = lambda wildcards, output: Path(output[[0]]).parent,
    shell:
    r"""
    {input.somalier_tool} extract \
        --sites {input.sites} \
        --fasta {input.ref} \
        --out-dir {params.outdir} \
        {input.vcf}
    """


rule relate:
    input:
        # TODO
        extracted = "",
        # ped = ""
        somalier_tool = config['somalier']['tool'],
    output:
        TODO
    # message:
    params:
        outdir = lambda wildcards, output: Path(output[[0]]).parent,
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
        # TODO
        extracted=""
        somalier_tool = config['somalier']['tool'],
        labels_1kg = config['somalier']['labels_1kg'],
        somalier_1kg = config['somalier']['somalier_1kg'],
    output:
    # message:
    params:
        outdir = lambda wildcards, output: Path(output[[0]]).parent,
    shell:
    r"""
    {input.somalier_tool} ancestry \
        --output-prefix {params.outdir}/somalier \
        --labels {input.labels_1kg} \
        {input.somalier_1kg} ++ \
        {input.extracted}
    """
