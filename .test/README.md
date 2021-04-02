# Testing

## Setup test datasets

* To setup test bam and vcf files, run:

```sh
cd .test
./setup_test_datasets.sh
```

* QuaC also needs test QC outputs for fastq (and sample rename config), which get created by small var caller pipeline.
  This was achieved by running the small variant caller pipeline using its test datasets with some modifications. Steps
  are briefly shown here:

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
