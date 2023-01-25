# Installation

Installation requires

- fetching the source code
- creating the conda environment

## Requirements

- Git v2.0+
- Anaconda/miniconda
    - Tested with Anaconda3/2020.02

!!! Cheaha-users-only 
    Available as module in Cheaha - `Anaconda3/2020.02`


## Retrieve pipeline source code

Go to the directory of your choice and run the command below.

```sh
git clone git@github.com:uab-cgds-worthey/quac.git
```


## Create conda environment

Conda environment will install all necessary dependencies, including snakemake, to run the QuaC workflow.

```sh
cd /path/to/quac/repo

# For use only at Cheaha in UAB. Load conda into environment.
module reset
module load Anaconda3/2020.02

# create conda environment. Needed only the first time.
conda env create --file configs/env/quac.yaml

# activate conda environment
conda activate quac

# if you need to update the existing environment
conda env update --file configs/env/quac.yaml
```
