[![Snakemake](https://img.shields.io/badge/snakemake-6.0.5-brightgreen.svg?style=flat)](https://snakemake.readthedocs.io)
[![ReadTheDocs](https://readthedocs.org/projects/quac/badge/?version=latest)](https://quac.readthedocs.io/en/stable/)
[![DOI JOSS](https://joss.theoj.org/papers/10.21105/joss.05313/status.svg)](https://doi.org/10.21105/joss.05313)
[![Zenodo](https://zenodo.org/badge/DOI/10.5281/zenodo.10002036.svg)](https://doi.org/10.5281/zenodo.10002036)

# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

> **_NOTE:_**  In a past life, QuaC used a different remote Git management provider, [UAB
> Gitlab](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/public/quac). It was migrated to
> Github in Jan 2023, and the Gitlab version has been archived.

## What is QuaC?

QuaC is a snakemake-based pipeline that runs several QC tools for WGS/WES samples and then summarizes their results
using pre-defined, configurable QC thresholds.

In summary, QuaC performs the following:

- Runs several QC tools using `BAM` and `VCF` files as input. At our center CGDS, these files are produced as part of
  the [small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
- Using [QuaC-Watch](./docs/quac_watch.md) tool, it performs QC checkup based on the expected thresholds for certain QC metrics and summarizes
  the results for easier human consumption
- Aggregates QC output as well as QuaC-Watch output using MulitQC, both at the sample level and project level.
- Optionally, above mentioned QuaC-Watch and QC aggregation steps can accept pre-run results from few QC tools (fastqc,
   fastq-screen, picard's markduplicates) when run with flag `--include_prior_qc`. 

> **_NOTE:_**  QuaC is built to use with Human WGS/WES data. If you would like to use it with non-human data, please
> modify the pipeline as needed -- especially the thresholds used in QuaC-Watch configs.

## Documentation

Full documentation, including installation and how to run QuaC, is available at <https://quac.readthedocs.io>.

## Citing QuaC

If you use QuaC, please cite:

Gajapathy et al., (2023). QuaC: A Pipeline Implementing Quality Control Best Practices for Genome Sequencing and Exome Sequencing Data. Journal of Open Source Software, 8(90), 5313, <https://doi.org/10.21105/joss.05313>

## Repo owner

- **Mana**valan Gajapathy

## License

[GNU GPLv3](./LICENSE)

## Contributing

See [here](./docs/CONTRIBUTING.md) for contributing guidelines.

## Changelog

See [here](./docs/Changelog.md)
