# Sample QC review system

Consistent and understandable dissemination of QC review results can be challenging when quality issues are found, and
even more so when said issues alter the ability to accurately perform downstream analyses. To reduce this burden we
devised a “Sample QC review system” where QC review results get stored using controlled flags and get accompanied by
comments in free text as needed. This review system allows downstream users to quickly identify problematic samples and
their potential causes, and empowers them to quickly determine if those samples can be used for intended data analyses.
As not all users are proficient in interpreting results from various QC tools, this review system is of major assistance
and enables those less versed in QC of GS and ES to assess and ensure the quality of their samples.

!!! warning

    While this QC review system is helpful to broadly identify and filter samples based on their
    QC flags, please be wary of these shortcomings:

    * QC status assignment can sometimes be subjective. For example, differentiation between 
    flags `poor` and `fail` may depend on the person assigning them, type of downstream analyses
    planned, etc.
    * Our QC criteria may change over time as we gain more knowledge and implement new algorithms 
    tools. QC review results for older samples during such a scenario may or may not be kept up-to-date.


!!! note "CGDS users only"

    * AT CGDS, Sample QC review system is incorporated into "Sample Tracking Log" in Wrike.
    See fields/columns with prefix `[QC]` in "Sample Tracking Log" section for your project. 

## Description of fields

Fields shown in the table below are used to capture the summarized QC results.

| Field                       | Explanation                                                                       | Allowed values |
| --------------------------- | --------------------------------------------------------------------------------- | -------------- |
| Sample - Overall Status     | Overall QC status considering results of all QC performed                         | Type 1 flags   |
| FASTQ                       | Overall QC status considering results of all QC performed at fastq level          | Type 1 flags   |
| FASTQ Comment               | Comments on QC at fastq level (eg. small insert size, high adapter content, etc.) | Free text      |
| BAM                         | Overall QC status considering results of all QC performed at bam level            | Type 1 flags   |
| BAM Comment                 | Comments on QC at bam level (eg. low mean coverage, high duplication rate, etc.)  | Free text      |
| Other Species Contamination | Checks for sample contamination due to other species' genomic material            | Type 1 flags   |
| Human Cross-contamination   | Checks for sample contamination due to other human's genomic material             | Type 1 flags   |
| Sex Check                   | Checks if predicted sex matches self-reported sex                                 | Type 2 flags   |
| Relatedness Check           | Checks if predicted relatedness matches self-reported relatedness                 | Type 2 flags   |
| Ancestry Check              | Checks if predicted ancestry matches self-reported ancestry                       | Type 2 flags   |
| Other Comments/Notes        | Any other comments/notes concerning QC                                            | Free text      |

### Flags used

Controlled status value to communicate the state of QC at various levels. Here are their definitions:

#### Type 1 flags

| Flag         | Explanation                                                                                |
| ------------ | ------------------------------------------------------------------------------------------ |
| `pass`       | Passes all QC checks performed                                                             |
| `acceptable` | *Minor* problems were identified during QC but they are not expected to affect their usage |
| `poor`       | *Major* problems were identified during QC AND this likely would affect their usage        |
| `fail`       | Fails QC check(s) performed AND this is expected to severely affect their usage            |

#### Type 2 flags

| Flag             | Explanation                                                                    |
| ---------------- | ------------------------------------------------------------------------------ |
| `pass`           | Estimated/predicted value *matches* user-provided value                        |
| `fail`           | Estimated/predicted value *does not match* user-provided value                 |
| `not applicable` | QC check not applicable as user-provided value is not available for the sample |
