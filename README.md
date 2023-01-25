# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

## What is QuaC?

QuaC is a snakemake-based pipeline that runs several QC tools for WGS/WES samples and then summarizes their results
using pre-defined, configurable QC thresholds. 

In summary, QuaC performs the following:

- Runs several QC tools using `BAM` and `VCF` files as input. At our center CGDS, these files are produced as part of
  the [small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
- Using *QuaC-Watch* tool, it performs QC checkup based on the expected thresholds for certain QC metrics and summarizes
  the results for easier human consumption
- Aggregates QC output produced here as well as those by the small variant caller pipeline using mulitqc, both at the
  sample level and project level.
- Optionally, above mentioned QC checkup and QC aggregation steps can accept pre-run results from few QC tools (fastqc,
   fastq-screen, picard's markduplicates). At CGDS, these files are produced as part of the [small variant caller
   pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).


### QC tools utilized

QuaC quacks using the tools listed below:

| Tool                                                                                                                       | Use                                                                                               | QC Type                                  |
| -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| [Qualimap](http://qualimap.conesalab.org/)                                                                                 | Summarizes several alignment metrics using BAM file                                               | BAM quality                              |
| [Picard-CollectMultipleMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectMultipleMetrics) | Summarizes alignment metrics from BAM file using several modules                                  | BAM quality                              |
| [Picard-CollectWgsMetrics](https://broadinstitute.github.io/picard/command-line-overview.html#CollectWgsMetrics)           | Collects metrics about coverage and performance using BAM file                                    | BAM quality                              |
| [mosdepth](https://github.com/brentp/mosdepth)                                                                             | Fast alignment depth calculation using BAM file                                                   | BAM quality                              |
| [indexcov](https://github.com/brentp/goleft/tree/master/indexcov)                                                          | Estimate coverage from BAM index for GS (*Skipped in exome mode*)                                 | BAM quality                              |
| [covviz](https://github.com/brwnj/covviz)                                                                                  | Identifies large, coverage-based anomalies for GS using Indexcov output (*Skipped in exome mode*) | BAM quality                              |
| [bcftools stats](https://samtools.github.io/bcftools/bcftools.html#stats)                                                  | Summarizes VCF file stats                                                                         | VCF quality                              |
| [verifybamid](https://github.com/Griffan/VerifyBamID)                                                                      | Estimates within-species (i.e., cross-sample) contamination using BAM file                        | Within-species contamination             |
| [somalier](https://github.com/brentp/somalier)                                                                             | Estimation of sex, ancestry and relatedness using BAM file                                        | Sex, ancestry and relatedness estimation |


#### Optional tools' results consumption

[TODO clean up this paragraph] In addition to the above tools, optionally QuaC can also utilize QC results produced by
the tools below when run with flag `--include_prior_qc`. At CGDS, these files are produced as part of the [small variant
caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).


| Tool                                                                                                         | Use                                               | QC            |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- | ------------- |
| [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)                                         | Performs QC on raw sequence reads data (FASTQ)    | FASTQ quality |
| [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)                             | Screens FASTQ for other-species contamination     | FASTQ quality |
| [Picard's MarkDuplicates](https://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates) | Determines level of read duplication on BAM files | BAM quality   |


## Contributing

If you like to make changes to the source code, please see the [contribution guidelines](./CONTRIBUTING.md).

## Changelog

See [here](./Changelog.md).

## Repo owner

* *Mana*valan Gajapathy

