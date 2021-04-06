import re

def get_samples(ped_fpath):
    """
    Parse pedigree file and return sample names
    """
    samples = ()
    with open(ped_fpath, "r") as f_handle:
        for line in f_handle:
            if line.startswith("#"):
                continue
            sample = line.split("\t")[1]
            samples += (sample,)

    return samples


def is_testing_mode():
    "checks if testing dataset is used as input for the pipeline"

    if ".test/" in str(PROJECT_PATH):
        return True

    return None


def get_capture_regions_bed(wildcards):
    "returns capture bed file (if any) used by small variant caller pipeline"

    config_dir = PROJECT_PATH / wildcards.sample / "configs" / "small_variant_caller"
    bed = list(config_dir.glob('*.bed'))
    bed += list(config_dir.glob('*.bed.gz'))

    if len(bed) > 1:
        print (f"ERROR: More then one capture bed file found for sample {wildcards.sample} - {bed}")
        raise SystemExit(1)

    return bed


def get_small_var_pipeline_targets(wildcards):
    """
    Returns target files that are output by small variant caller pipeline.
    Uses deduplication's output files as proxy to identify "units"
    """

    flist = (PROJECT_PATH / wildcards.sample / "qc" / "dedup").glob("*.metrics.txt")
    units = []
    for fpath in flist:
        unit = re.match(fr"{wildcards.sample}-(\d+).metrics.txt", fpath.name)
        units.append(unit.group(1))

    targets = expand([
            PROJECT_PATH / "{{sample}}" / "qc" / "fastqc-raw" / "{{sample}}-{unit}-{read}_fastqc.zip",
            PROJECT_PATH / "{{sample}}" / "qc" / "fastqc-trimmed" / "{{sample}}-{unit}-{read}_fastqc.zip",
            PROJECT_PATH / "{{sample}}" / "qc" / "fastq_screen-trimmed" / "{{sample}}-{unit}-{read}_screen.txt",
            PROJECT_PATH / "{{sample}}" / "qc" / "dedup" / "{{sample}}-{unit}.metrics.txt",
        ], unit=units, read=["R1", "R2"]),

    return targets[0]



def aggregate_rename_configs(rename_config_files, outfile):
    "aggregate input rename-configs into a single file"

    header_string = "Original labels\tRenamed labels"
    aggregated_data = [header_string]
    for fpath in rename_config_files:
        with open(fpath) as fh:
            for line_no, line in enumerate(fh):
                line = line.strip("\n")

                if not line_no:
                    if line != "Original labels\tRenamed labels":
                        print(f"Unexpected header string in file '{fpath}'")
                        raise SystemExit(1)
                else:
                    aggregated_data.append(line)

    with open(outfile, "w") as out_handle:
        out_handle.write("\n".join(aggregated_data))

    return None


#### configs from cli ####
OUT_DIR = Path(config["out_dir"])
PROJECT_NAME = config["project_name"]
PROJECT_PATH = Path(config["projects_path"]) / PROJECT_NAME / "analysis"
PEDIGREE_FPATH = config["ped"]
EXOME_MODE = config["exome"]

#### configs from configfile ####
RULE_LOGS_PATH = Path(config["log_dir"]) / "rule_logs"
RULE_LOGS_PATH.mkdir(parents=True, exist_ok=True)

SAMPLES = get_samples(PEDIGREE_FPATH)

