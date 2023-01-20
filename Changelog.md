# CHANGELOG

Changelog format to use:

```
YYYY-MM-DD  John Doe

* Big Change 1:
    <reasoning here>
* Another Change 2:
    <reasoning here>
```
---

2021-03-16  Manavalan Gajapathy

* Creates QuaC workflow, which can run somalier, mosdepth, indexcov, covviz and verifybamid2
* Uses pedigree file as input
* Makes it production ready.

2021-05-28  Manavalan Gajapathy

* QuaC is heavily reworked to be a companion pipeline to small variant caller pipeline and will now perform most of the
  QC analyses for WGS/WES data. While the small caller pipeline will still run few QC tools (for pragmatic reasons),
  QuaC will now take over the heavylifting of QC, including the QC-checkup, which is now called as QuaC-Watch.
* Runs in containerized environment using Singularity.
* QuaC can perform both sample-level and project-level QC. This is the major reason why it was decided to separate QC from small-variant caller pipeline, as it could only perform single-sample QC.
* More QC tools were added
* For QC checkup (ie. QuaC-Watch), QuaC now heavily expands to vcf metrics and adds significant amount of QC thresholds for bam metrics.
* QuaC's input are output from the small variant caller pipeline, and former's output will fit seemlessly with the latter's output.
* QuaC accepts pedigree file as input. A dummy pedigree file creator script is provided, which will be handy until phenotips is made available to us.
* System-level testing is added

2021-06-08  Manavalan Gajapathy

* Bugfix: Fixes error when there is only one sample in input ped file (#34)
* Adds system-testing for such only-one-sample-in-input setup (#35).

2022-04-07  Manavalan Gajapathy

* Previously hardcoded hardware resources for snakemake rules can now be supplied via `configs/workflow.yaml` (closes #48)
* Modified multiqc conda env config to use explicit dependencies to get around installation issues (closes #47)


2023-01-20  Manavalan Gajapathy

As part of making QuaC publicly available, following updates were made to make it more generic to the environment and user friendly:

* Removes prerun QC from small variant caller pipeline as requirement to QuaC (closes #45)
* Explicitly defines conda environments (closes #49)
* Uses container solution for `covviz` installation instead of conda to avoid pip based installation (closes #52)
* Removes git submodules and instead saves their local copy to repo (closes #53)
* Loads singularity module loading prior to executing the runner script
* Uses minimal snakemake instead of full-featured snakemake (closes #56)