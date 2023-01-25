# QuaC-Watch

QuaC includes a tool called QuaC-Watch. After QuaC runs the QC tools for samples, QuaC-Watch summarizes if samples
have passed the configurable QC thresholds defined using config files (available at
[`configs/quac_watch/`](./configs/quac_watch/)), both at the sample level as well as project level. This summary makes
it easy to quickly review whether sample(s) are of sufficient quality and highlight samples that need further
review.


QuaC includes a tool called QuaC-Watch, which consumes results from several QC tools, compares QC metrics against the acceptable thresholds, and summarizes results using color-coded pass/fail flags for efficient review.  This summary allows users to quickly review output from multiple QC tools, identify whether samples meet expected quality thresholds, and readily highlight samples that need further review. 

Reasonable default thresholds for QC metrics have been built into QuaC-Watch but can be configured by a user for scenarios using `--quac_watch_config`. Default thresholds:

* [For Genome sequencing](https://github.com/uab-cgds-worthey/quac/blob/master/configs/quac_watch/exome_quac_watch_config.yaml)
* [For Exome sequencing](https://github.com/uab-cgds-worthey/quac/blob/master/configs/quac_watch/wgs_quac_watch_config.yaml)

These thresholds were curated based on

* literature [@marshall_best_2020; @ kobren_commonalities_2021] 
* in-house analyses using hundreds of GS and ES samples
* knowledge gained from our past sample QC experiences 


!!! tip
    Custom configs for QuaC-Watch can be provided via `--quac_watch_config`.
