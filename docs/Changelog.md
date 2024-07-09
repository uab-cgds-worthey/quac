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

2024-07-08  Brandon Wilk

* Makes minor bug fix for issue #95 found in the test run detection logging function

2023-10-09  Manavalan Gajapathy

- Makes minor documentation updates - updating citation info, adding JOSS badge and updating zenodo badge to use generic
  DOI

* Merges `joss_manuscript` to the `master` branch to bring it up to date.

2023-10-06  Manavalan Gajapathy

* Adds documentation on providing sample filepaths via user-provided sample config file due to recent PRs #87, #88, #89
  and #90 (closes #86).
* Adds documentation on editing thresholds in the QuaC-Watch config file (closes #85)

2023-10-05  Manavalan Gajapathy

* Refactors to accept sample filepaths via user-provided sample config file, when `--allow_sample_renaming` is used (#86)

2023-10-05  Manavalan Gajapathy

* Refactors to accept sample filepaths via user-provided sample config file, when `--include_prior_qc` is used (#86)
* Adds a test sample config file that includes priorQC filepaths

2023-10-05  Manavalan Gajapathy

* Refactors to accept sample filepaths via user-provided sample config file. Only for exome mode in minimal manner (w/o
  --include_prior_qc, --allow_sample_renaming) (#86)
* Adds a test sample config file
* Refactors to get capture bed file as input from the sample configfile

2023-10-05  Manavalan Gajapathy

* Refactors to accept sample filepaths via user-provided sample config file. Only for WGS mode in minimal manner (w/o
  --include_prior_qc, --allow_sample_renaming) (#86)
* Adds sample config file to use with system testing datasets -
  `.test/configs/no_priorQC/sample_config/project_2samples.tsv`. This provides map of sample name to their VCF and BAM
  filepaths.
* Refactors use of `--sample_config` arg to work with this config file as input
* Deprecates args `--project_name` and `--projects_path`
* Modifies workflow to use the new input setup
* Updates README concerning the changes made

2023-07-17  Manavalan Gajapathy

* Minor updates to documentation.


2023-07-16  Manavalan Gajapathy

* Updates doc based on users feedback. 


2023-06-30  Manavalan Gajapathy

* Merges `joss_manuscript` to the `master` branch to bring it up to date. 


2023-06-22  Manavalan Gajapathy

* Refactors CLI script to accounting for user's environment specific slurm args requirements when submitting job to
  slurm (#76)
* Removes CLI option `--rerun_failed` and instead configures it via snakemake-slurm profile
  (`src/slurm/slurm_profile/config.yaml`)
* Removes `--subtasks_slurm option` and `--snakemake_slurm` as they were redundant
* Checks if tool dependencies are available in user environment.
* Adds `time` resource to `configs/snakemake_cluster_config.json`
* Removes PR trigger from system testing github actions.
* Tests if singularity is working as expected in user machine


2023-05-31  Manavalan Gajapathy

* Adds system testing as github actions workflow


2023-05-18  Manavalan Gajapathy

* Constructs snakemake's `sbatch` command using args and values from cluster config file supplied via
  `--cluster_config`.
* Updates doc to include cluster config as a requirement


2023-05-09  Manavalan Gajapathy

* Adds a verification step in the CLI wrapper script to check if the file/dirpaths to be mounted to singularity already
  exist as expected (#71)
* Resolves dirpaths of datasets in the workflow config file to obtain their full path

2023-04-10  Manavalan Gajapathy

* Refactors snakemake pipeline to fully run jobs in direct singularity containers. No more creation of conda environment
  using singularity containers! (#69)


2023-04-04  Manavalan Gajapathy

* Retires use of cheaha-specific env variable $USER_SCRATCH
* Auto-creates user-provided dir structures for `--outdir`, `--tmp_dir`, and `--log_dir`


2023-03-01  Manavalan Gajapathy

* Decouples readme.md from readthedocs setup


2023-02-28  Manavalan Gajapathy

* Adds license
* Bugfix: Changes github PR template filepath


2023-01-31  Manavalan Gajapathy

Restructures the docs to make it clearer to non-Cheaha users, updates documentation to reflect recent CLI option
changes, and hosts docs publicly using readthedocs.

* `Readme.md` has grown bigger and became difficult to navigate. Especially for non-Cheaha users. So documentation in
  readme.md is now restructured to break into multiple files and is now easier to consume.
     * Makes the doc generic to non-Cheaha users
     * Identifies parts of the docs that are specific to Cheaha or CGDS users
* Updates doc to reflect changes made in #59 
* Now hosts doc for "Sample QC review system".
* Uses [mkdocs](https://www.mkdocs.org/) to create static site for documentation.
* Hosts QuaC docs using [ReadTheDocs](https://readthedocs.org/) 
* Migrates Gitlab MR template to Github PR template
* Adds github action to identify broken links in markdown files


2023-01-27  Manavalan Gajapathy

In efforts to make the repo generic to non-cheaha users, following changes were made:

* Removes default quac_watch_config as it can lead to errors (#39)
* Makes slurm schedule as dependency; now quac can be run locally. Local run is the default and `--use_slurm` allows
  running snakemake-triggered jobs in slurm. (#57)
* Allows users to define custom slurm partitions and time limits via workflow configs (#58)
* Updates median insert size threshold in quac-watch config (#54)

2023-01-20  Manavalan Gajapathy

As part of making QuaC publicly available, following updates were made to make it more generic to the environment and
user friendly:

* Removes prerun QC from small variant caller pipeline as requirement to QuaC (closes #45)
* Explicitly defines conda environments (closes #49)
* Uses container solution for `covviz` installation instead of conda to avoid pip based installation (closes #52)
* Removes git submodules and instead saves their local copy to repo (closes #53)
* Loads singularity module loading prior to executing the runner script
* Uses minimal snakemake instead of full-featured snakemake (closes #56)


2022-04-07  Manavalan Gajapathy

* Previously hardcoded hardware resources for snakemake rules can now be supplied via `configs/workflow.yaml` (closes
  #48)
* Modified multiqc conda env config to use explicit dependencies to get around installation issues (closes #47)


2021-06-08  Manavalan Gajapathy

* Bugfix: Fixes error when there is only one sample in input ped file (#34)
* Adds system-testing for such only-one-sample-in-input setup (#35).


2021-05-28  Manavalan Gajapathy

* QuaC is heavily reworked to be a companion pipeline to small variant caller pipeline and will now perform most of the
  QC analyses for WGS/WES data. While the small caller pipeline will still run few QC tools (for pragmatic reasons),
  QuaC will now take over the heavylifting of QC, including the QC-checkup, which is now called as QuaC-Watch.
* Runs in containerized environment using Singularity.
* QuaC can perform both sample-level and project-level QC. This is the major reason why it was decided to separate QC
  from small-variant caller pipeline, as it could only perform single-sample QC.
* More QC tools were added
* For QC checkup (ie. QuaC-Watch), QuaC now heavily expands to vcf metrics and adds significant amount of QC thresholds
  for bam metrics.
* QuaC's input are output from the small variant caller pipeline, and former's output will fit seemlessly with the
  latter's output.
* QuaC accepts pedigree file as input. A dummy pedigree file creator script is provided, which will be handy until
  phenotips is made available to us.
* System-level testing is added


2021-03-16  Manavalan Gajapathy

* Creates QuaC workflow, which can run somalier, mosdepth, indexcov, covviz and verifybamid2
* Uses pedigree file as input
* Makes it production ready.
