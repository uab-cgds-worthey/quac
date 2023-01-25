# Visualization of pipeline

[Visualization of the pipeline](https://snakemake.readthedocs.io/en/stable/executing/cluster-cloud.html#visualization)
based on the test datasets are available in [directory `pipeline_visualized`](./pipeline_visualized/). Commands used to
create this visualization:

```sh
# open interactive node
srun --ntasks=1 --cpus-per-task=1 --mem-per-cpu=4096 --partition=express --pty /bin/bash

# For Cheaha users only. Set up environment. 
module reset
module load Anaconda3/2020.02
module load Singularity/3.5.2-GCC-5.4.0-2.26

# activate conda env
conda activate quac

DAG_DIR="pipeline_visualized"

###### WGS mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/wgs_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/wgs_rulegraph.png"

###### Exome mode ######
# DAG
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --exome \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --run_locally --extra_args "--dag -F | dot -Tpng > ${DAG_DIR}/exome_dag.png"

# Rulegraph - less informative than DAG at sample level but less dense than DAG makes this easier to skim
python src/run_quac.py \
      --project_name test_project \
      --projects_path .test/ngs-data/ \
      --pedigree .test/configs/project_2_samples.ped \
      --exome \
      --quac_watch_config "configs/quac_watch/exome_quac_watch_config.yaml" \
      --run_locally --extra_args "--rulegraph -F | dot -Tpng > ${DAG_DIR}/exome_rulegraph.png"
```
