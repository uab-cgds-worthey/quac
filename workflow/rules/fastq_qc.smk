rule fastqc:
    input:
        get_fastq_by_read
    output:
        html=protected(str(OUT_DIR) + "/{sample}/qc/fastqc-raw/{sample}-{unit}-{read}_fastqc.html"),
        zip=protected(str(OUT_DIR) + "/{sample}/qc/fastqc-raw/{sample}-{unit}-{read}_fastqc.zip")
    params:
        input_base=lambda wildcards, input: Path(input[0]).name.replace(".gz", "").replace(".fastq", "").replace(".fq", ""),
    singularity:
        "docker://quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
    shell:
        r"""
        # use a temp dir to avoid race conditions 
        # (https://github.com/snakemake/snakemake-wrappers/blob/0.64.0/bio/fastqc/wrapper.py#L28)
        TMP_DIR=$(mktemp -d -p /tmp)

        # remove the directory when job is completed (successfully or not)
        trap 'rm -rf "$TMP_DIR"' EXIT

        fastqc \
            --threads {threads} \
            --quiet \
            --outdir "$TMP_DIR" \
            {input[0]:q}

        # rename outfiles
        HTML_PATH="${{TMP_DIR}}/{params.input_base}_fastqc.html"
        if [ "$HTML_PATH" != "{output.html}" ]; then
            mv "$HTML_PATH" "{output.html}"
        fi

        ZIP_PATH="${{TMP_DIR}}/{params.input_base}_fastqc.zip"
        if [ "$ZIP_PATH" != "{output.zip}" ]; then
            mv "$ZIP_PATH" "{output.zip}"
        fi
        """


rule fastq_screen:
    input:
        fastq = get_fastq_by_read,
        config_f = config["datasets"]["fastq_screen_config"]
    output:
        txt=protected(str(OUT_DIR) + "/{sample}/qc/fastq_screen-raw/{sample}-{unit}-{read}_screen.txt"),
        # png=protected(str(OUT_DIR) + "/{sample}/qc/fastq_screen-raw/{sample}-{unit}-{read}_screen.png"),
        html=protected(str(OUT_DIR) + "/{sample}/qc/fastq_screen-raw/{sample}-{unit}-{read}_screen.html"),
    singularity:
        "docker://quay.io/biocontainers/fastq-screen:0.16.0--pl5321hdfd78af_0"
    params:
        outdir = lambda wildcards, output: str(Path(output[0]).parent),
        fastq_prefix = lambda wildcards, input: get_basename_stem(input['fastq'])
    shell:
        r"""
        fastq_screen \
            --aligner bowtie2 \
            --threads {threads} \
            --force \
            --conf {input.config_f} \
            --outdir {params.outdir} \
            {input.fastq}

        # rename output files as needed
        mv "{params.outdir}/{params.fastq_prefix}_screen.txt" "{output.txt}"
        mv "{params.outdir}/{params.fastq_prefix}_screen.html" "{output.html}"
        """


localrules: multiqc_sample_renaming
rule multiqc_sample_renaming:
    output:
        protected(str(OUT_DIR) + "/{sample}/qc/multiqc_initial_pass/multiqc_sample_rename_config/{sample}_rename_config.tsv"),
    # WARNING: don't put this rule in a group, bad things will happen. see issue #23 in gitlab
    message:
        "Writes sample rename config file to use with multiqc"
    run:
        write_sample_rename_config(output[0])
