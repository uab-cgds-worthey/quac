# QuaC

🦆🦆 Don't duck that QC thingy 🦆🦆

## Who am I?

QuaC is a pipeline developed using snakemake, which runs a set of selected QC tools on NGS samples.

## What can I quac about?

| Tool                                                              | Use                                                        |
| ----------------------------------------------------------------- | ---------------------------------------------------------- |
| [somalier](https://github.com/brentp/somalier)                    | Estimation of sex, ancestry and relatedness                |
| [verifybamid](https://github.com/Griffan/VerifyBamID)             | Estimates within-species (i.e. cross-sample) contamination |
| [mosdepth](https://github.com/brentp/mosdepth)                    | Fast BAM/CRAM depth calculation                            |
| [indexcov](https://github.com/brentp/goleft/tree/master/indexcov) | Estimate coverage from whole-genome bam or cram index      |
| [covviz](https://github.com/brwnj/covviz)                         | Identifies large, coverage-based anomalies                 |


## Installation

Installation simply requires fetching the source code. Following are required:

- Git
- CGDS GitLab access
- [SSH Key for access](https://docs.uabgrid.uab.edu/wiki/Cheaha_GettingStarted#Logging_in_to_Cheaha) to Cheaha cluster

To fetch source code, change in to directory of your choice and run:

```sh
git clone -b master \
    --recurse-submodules \
    git@gitlab.rc.uab.edu:center-for-computational-genomics-and-data-science/sciops/pipelines/quac.git
```

Note that this repository uses git submodules, which gets automatically pulled when cloning using above command. Simply
downloading this repository from GitLab, instead of cloning, may not fetch the submodules included.

## Environment Setup

### Requirements

- Anaconda/miniconda

Also the tools listed below, which are not available via conda distribution, need to be installed. Static binaries are
available for both these tools and they are hence easy to install.

- [somalier](https://github.com/brentp/somalier)
- [goleft](https://github.com/brentp/goleft)

*Note:* CGDS folks using QuaC in cheaha may skip this step, as these tools are already installed and centrally available.

### Setup config file

Workflow config file `configs/workflow.yaml` provides path to certain tool installation path as well as other files that
the tools require. Modify them as necessary. Refer to the QC tool's documentation for more information on files that
they require.

### Create conda environment

```sh
module reset
module load Anaconda3/2020.02

# create conda environment. Needed only the first time.
conda env create --file configs/env/quac.yaml
# activate conda environment
conda activate quac

# if you need to update the existing environment
conda env update --file configs/env/quac.yaml

```



If the default path to `datasets_central` is going to be used (i.e. you'll be using the tool for testing and/or
development), then you'll also need to initialize the default `datasets_central` directory. This can be done by running
the following (must be done for each user):

```sh
mkdir -p $USER_SCRATCH/tmp/datasets_central_manager/datasets $USER_SCRATCH/tmp/datasets_central_manager/logs
```


### Prep VerifyBamID datasets for exome analysis

Need to add `chr` prefix to contigs.

```sh
# cd into exome resources dir
cd /path/to/VerifyBamID-2.0.1/resource/exome/
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.bed > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.bed
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.mu > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.mu
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.UD 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.UD
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.V 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.V
```
