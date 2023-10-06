# Input/Output

## Input

### Sample config file

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

### Pedigree file

<!-- markdown-link-check-disable -->

Samples belonging to a project are provided as input via `--pedigree` to QuaC in [pedigree file
format](https://gatk.broadinstitute.org/hc/en-us/articles/360035531972-PED-Pedigree-format). Only the samples that are
supplied in pedigree file will be processed by QuaC and all of these samples must belong to the same project.

<!-- markdown-link-check-enable -->

!!! note "CGDS users only"

    QuaC repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) to
    create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
    affected status info. See header of the script for usage instructions. 


*Optionally*, QuaC can also utilize QC results produced by [certain
tools](./index.md#optional-qc-output-consumed-by-quac) when run with flag `--include_prior_qc`. In this case, following
directory structure is expected.


!!! note "CGDS users only"

    Output (bam, vcf and QC output) produced by CGDS's small variant caller pipeline can be readily used as input to
    QuaC with flags `--include_prior_qc` and `--allow_sample_renaming`.

### Example project structure

Refer to system testing directory `.test/` in the repo for an example project to see an example project with above
mentioned directory structure needed as input. In this setup, projects A and B have prior QC data included, whereas
samples C and D do not have them. Refer to pedigree files under `.test/configs/` on how these example samples were used
as input to QuaC. 


## Output

QuaC results are stored at the path specified via option `--outdir` (default:
`data/quac/results/test_project/analysis`).  Refer to the [system testing's
output](./system_testing.md#expected-output-files) to learn more about the output directory structure. 

!!! tip

    Users may primarily be interested in the aggregated QC results produced by [multiqc](https://multiqc.info/),
    both at sample-level as well as at the project-level. These multiqc reports also include summary of QuaC-Watch
    results at the top.

!!! note "CGDS users only"

    QuaC's output directory structure was designed based on the output structure of the [CGDS small variant caller
    pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

