# QuaC

## How to run QuaC

### Input requirements

- Pedigree file supplied via `--pedigree`. Only the samples that are supplied in pedigree file will be processed by QuaC
  and all of these samples must belong to the same project.
  - *For CGDS use only*: This repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) that can
  create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
  affected status info. See header of the script for usage instructions. Note that we plan to use
  [phenotips](https://phenotips.com/) in future to produce fully capable pedigree file. One could manually create them
  as well, but this could be error-prone.

- Input `BAM` and `VCF` files 



### Example usage

```sh
# to quack on a WGS project, which also has prior QC data
PROJECT="Quack_Quack"
python src/run_quac.py \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --include_prior_qc \
      --allow_sample_renaming


# to quack on a WGS project, run in a medium slurm partition and write results to a dir of choice
PROJECT="Quack_This"
python src/run_quac.py \
      --slurm_partition medium \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --outdir "$USER_SCRATCH/tmp/quac/results/test_${PROJECT}/analysis"


# to quack on an exome project
PROJECT="Quack_That"
python src/run_quac.py \
      --project_name $PROJECT \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome

# to quack on an exome project by providing path to that project
PROJECT="Quack_That"
python src/run_quac.py \
      --project_name $PROJECT \
      --projects_path "/path/to/project/${$PROJECT}/" \
      --pedigree "data/raw/ped/${PROJECT}.ped" \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --exome
```


```
cd /data/temporary-scratch/manag/tmp/quac/results/test_project_2_samples_wgs/analysis/ rm -rf
./*/qc/multiqc_*/ ./*/qc/quac_watch rm -rf ./project_level_qc/multiqc/
```

