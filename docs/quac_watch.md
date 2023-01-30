# QuaC-Watch

QuaC includes a tool called QuaC-Watch, which consumes results from several QC tools, compares QC metrics against the
acceptable thresholds, and summarizes results using color-coded pass/fail flags for efficient review.  This summary
allows users to quickly review output from multiple QC tools, identify whether samples meet expected quality thresholds,
and readily highlight samples that need further review. 

We provide pre-defined thresholds for QC metrics as part of the QuaC repo and they need to be supplied via `--quac_watch_config`:

* For Genome sequencing - [configs/quac_watch/wgs_quac_watch_config.yaml](../configs/quac_watch/wgs_quac_watch_config.yaml)
* For Exome sequencing - [configs/quac_watch/exome_quac_watch_config.yaml](../configs/quac_watch/exome_quac_watch_config.yaml)

These thresholds were curated based on

* literature 
* in-house analyses using hundreds of GS and ES samples
* knowledge gained from our past sample QC experiences 
