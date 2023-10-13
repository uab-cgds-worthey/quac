# Input/Output

## Input

### Sample config file

Sample identifier and their necessary filepaths (`bam`, `vcf`, etc.) are provided to QuaC in a `tsv` formatted config
file via `--sample_config`. Columns required depend on the flags supplied to `src/run_quac.py`. This table lists the
allowed columns and when to use them.

| Column                | When to use               | Description                                                                                           |
| --------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------- |
| sample_id             | Always                    | Sample identifier                                                                                     |
| bam                   | Always                    | BAM filepath                                                                                          |
| vcf                   | Always                    | VCF filepath                                                                                          |
| capture_bed           | `--exome`                 | Capture region bed filepath                                                                           |
| fastqc_raw            | `--include_prior_qc`      | Filepath to FastQC `zip` files created from raw fastqs. Use comma as delimiter if multiple files.     |
| fastqc_trimmed        | `--include_prior_qc`      | Filepath to FastQC `zip` files created from trimmed fastqs. Use comma as delimiter if multiple files. |
| fastq_screen          | `--include_prior_qc`      | Filepath to FastQ Screen `txt` files. Use comma as delimiter if multiple files.                       |
| dedup                 | `--include_prior_qc`      | Filepath to Picard's MarkDuplicates `txt` files. Use comma as delimiter if multiple files.            |
| multiqc_rename_config | `--allow_sample_renaming` | Filepath to label rename configfile to use with multiqc                                               |

Refer to our system testing directory for example sample config files at `.test/configs`. For example:

* `.test/configs/no_priorQC/sample_config/project_2samples_wgs.tsv` - Sample config file for WGS samples and no prior
  QC.
* `.test/configs/no_priorQC/sample_config/project_2samples_exome.tsv` - Sample config file for exome samples and no
  prior QC. Note that WGS and exome samples can't be used in the same config file.
* `.test/configs/include_priorQC/sample_config/project_2samples_wgs.tsv` - Sample config file for WGS samples with prior
  QC data available from [certain QC tools](./index.md#optional-qc-output-consumed-by-quac).

### Pedigree file

<!-- markdown-link-check-disable -->

QuaC requires a [pedigree
file](https://gatk.broadinstitute.org/hc/en-us/articles/360035531972-PED-Pedigree-format) as input via `--pedigree`.
Samples listed in this file must correspond to those in sample config file (`--sample_config`).

<!-- markdown-link-check-enable -->

!!! note "CGDS users only"

    QuaC repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) to
    create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
    affected status info. See header of the script for usage instructions. 

## Output

QuaC results are stored at the path specified via option `--outdir` (default:
`data/quac/results/test_project/analysis`). Refer to the [system testing's
output](./system_testing.md#expected-output-files) to learn more about the output directory structure.

QC output are stored at the sample level as well as the project level (ie. all samples considered together) depending on
the type of QC run. For example, Qualimap tool is run at the sample level whereas Somalier tool is run at the project
level. MultiQC reports are available both at the sample and project level.

!!! tip

    Users may primarily be interested in the aggregated QC results produced by [MultiQC](https://multiqc.info/),
    both at sample-level as well as at the project-level. These multiqc reports also include summary of QuaC-Watch
    results at the top.

!!! note "CGDS users only"

    QuaC's output directory structure was designed based on the output structure of the [CGDS small variant caller
    pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
