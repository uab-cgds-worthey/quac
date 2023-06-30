# System Testing

Input directory structure to QuaC is based on the output directory structure of the [Small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
Following files are necessary for testing:

1. bams
2. vcfs
3. Capture regions bed file - Required only for exome mode
4. QC output from tools fastqc, fastq-screen and picard-markduplicates - Required only if `priorQC` is used
5. Sample rename config - Required only if `priorQC` is used

**Note**: If `priorQC` is used, be sure to preserve directory structure used in the output of CGDS Small variant caller
pipeline.

## Setup test datasets

### Required

* To setup test bam, vcf and capture region bed files, which are from sub-sampled NA12878 data, run:

```sh
cd .test
./setup_test_datasets.sh
```

### Optional - priorQC mode

* If used in `priorQC` mode, QuaC also needs test QC outputs for fastq (and sample rename config), which at CGDS get
  created by the small var caller pipeline. Below, we create fastq QC and sample rename config using the small variant
  caller pipeline for samples `A` and `B`.

```sh
cd <small_var_caller_pipeline_dir>
cd .test/configs

# setup configs for test samples A and B
cp -r wgs A
cp -r wgs B

# now modify these files to rename sample-names as A and B - samples.tsv, units.tsv, user_io_config.yaml

# run the pipeline. Execute only the rules of interest for QuaC
IO_CONFIG=".test/configs/A/user_io_config.yaml"
./src/run_pipeline.py --io_config $IO_CONFIG -e="--until fastqc_before_trimming fastqc_after_trimming fastq_screen multiqc_sample_renaming mark_duplicates"
IO_CONFIG=".test/configs/B/user_io_config.yaml"
./src/run_pipeline.py --io_config $IO_CONFIG -e="--until fastqc_before_trimming fastqc_after_trimming fastq_screen multiqc_sample_renaming mark_duplicates"

# copy output qc files
cp -r <small_var_pipeline_outdir>/A/qc/ <quac_repo>/.test/ngs-data/test_project/analysis/A
cp -r <small_var_pipeline_outdir>/B/qc/ <quac_repo>/.test/ngs-data/test_project/analysis/B
```
