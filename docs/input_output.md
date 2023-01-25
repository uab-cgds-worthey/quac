# Input/Output

## Input

- Pedigree file supplied via `--pedigree`. Only the samples that are supplied in pedigree file will be processed by QuaC
  and all of these samples must belong to the same project.


!!! CGDS-users-only

    QuaC repo includes a handy script [`src/create_dummy_ped.py`](src/create_dummy_ped.py) to
    create a dummy pedigree file, which will lack sex (unless project tracking sheet is provided), relatedness and
    affected status info. See header of the script for usage instructions. 


- Input `BAM` and `VCF` files 

```
X/
├── bam
│   ├── X.bam
│   └── X.bam.bai
└── vcf
    ├── X.vcf.gz
    └── X.vcf.gz.tbi
```

```
X/
├── bam
│   ├── X.bam
│   └── X.bam.bai
├── configs
│   └── small_variant_caller
│       └── capture_regions.bed
└── vcf
    ├── X.vcf.gz
    └── X.vcf.gz.tbi
```

```
A/
├── bam
│   ├── A.bam
│   └── A.bam.bai
├── qc
│   ├── dedup
│   │   ├── A-1.metrics.txt
│   │   └── A-2.metrics.txt
│   ├── fastqc-raw
│   │   ├── ....
│   ├── fastqc-trimmed
│   │   ├── ....
│   ├── fastq_screen-trimmed
│   │   └── ....
│   └── multiqc_initial_pass
│       └── multiqc_sample_rename_config
│           └── A_rename_config.tsv
└── vcf
    ├── A.vcf.gz
    └── A.vcf.gz.tbi
```

- Output produced by [the small variant caller
  pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).
  This includes bam, vcf and QC output. Refer to [test sample dataset](.test/ngs-data/test_project/analysis/A), which is
  representative of the input required.

- QuaC workflow config file. Refer to [section here](#set-up-workflow-config-file) for more info.

- When run in exome mode, QuaC requires a capture-regions bed file at path
  `path_to_sample/configs/small_variant_caller/<capture_regions>.bed` for each sample.


## Output

QuaC results are stored at the path specified via option `--outdir` (default:
`$USER_SCRATCH/tmp/quac/results/test_project/analysis`).  Refer to the [system testing's output](./system_testing.md) to
learn more about the output directory structure. 

!!! tip 

    Users may primarily be interested in the aggregated QC results produced by [multiqc](https://multiqc.info/),
    both at sample-level as well as at the project-level. These multiqc reports also include summary of QuaC-Watch
    results at the top.

Note that QuaC's output directory structure was designed based on the output structure of the [CGDS small variant caller
pipeline](https://gitlab.rc.uab.edu/center-for-computational-genomics-and-data-science/sciops/pipelines/small_variant_caller_pipeline).

