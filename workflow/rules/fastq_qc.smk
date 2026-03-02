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
