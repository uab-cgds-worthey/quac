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
* QuaC can perform both sample-level and project-level QC. This is the major reason why it was decided to separate QC from small-variant caller pipeline, as it could only perform single-sample QC.
* More QC tools were added
* For QC checkup (ie. QuaC-Watch), QuaC now heavily expands to vcf metrics and adds significant amount of QC thresholds for bam metrics.
* QuaC's input are output from the small variant caller pipeline, and former's output will fit seemlessly with the latter's output.
* QuaC accepts pedigree file as input. A dummy pedigree file creator script is provided, which will be handy until phenotips is made available to us.
* System-level testing is added
