# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

## What can I quac about?

* Somalier
  * Relatedness
  * Sex
  * Ancestry
* indexcov
  * (Estimated) coverage of smaples


## How to quac?

* Modify config file `configs/workflow.yaml` as needed. Note: `projects_path` and `project_name` may be the most
  important ones you would care about.
* Pedigree file specific to the project is required. Should be stored as `data/raw/ped/<project_name>.ped`.
* See the header of `workflow/Snakefile` for usage instructions on how to run the workflow


```sh
module reset
module load Anaconda3/2020.02

# create conda environment. Needed only the first time.
conda env create --file configs/env/quac.yaml

# if you need to update existing environment
conda env update --file configs/env/quac.yaml

# activate conda environment
conda activate quac
```
