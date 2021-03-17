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

Workflow config file `configs/workflow.yaml` provides path to path to necessary QC tools as well as other files that
some QC tools require. Modify them as necessary. Refer to the QC tool's documentation for more information on files that
they require.

#### Prepare verifybamid datasets for exome analysis

*This step is necessary only for exome samples.* verifybamid has provided auxiliary resource files, which are necessary
for analysis. However, chromosome contigs do not include `chr` prefix in their exome resource files, which are expected for
our analysis. Follow these steps to setup resource files with `chr` prefix in their contig names.

```sh
# cd into exome resources dir
cd <path-to>/VerifyBamID-2.0.1/resource/exome/
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.bed > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.bed
sed -e 's/^/chr/' 1000g.phase3.10k.b38.exome.vcf.gz.dat.mu > 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.mu
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.UD 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.UD
cp 1000g.phase3.10k.b38.exome.vcf.gz.dat.V 1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.V
```

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

