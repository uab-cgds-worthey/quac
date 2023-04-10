import re
from pathlib import PurePath
from snakemake.logging import logger


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

    query = ".test"
    if query in PurePath(PROJECT_PATH).parts:
        logger.info(f"// WARNING: '{query}' present in the path supplied via --projects_path. So testing mode is used.")
        return True

    return None


def get_capture_regions_bed(wildcards):
    "returns capture bed file (if any) used by small variant caller pipeline"

    config_dir = PROJECT_PATH / wildcards.sample / "configs" / "small_variant_caller"
    compressed_bed = list(config_dir.glob("*.bed.gz"))
    if compressed_bed:
        logger.error(
            f"ERROR: Compressed capture bed file found for sample {wildcards.sample}, "
            "but it is not supported by some QC tools used in QuaC (eg. qualimap). "
            f"Use compressed bed file instead. - {compressed_bed}"
        )
        raise SystemExit(1)

    bed = list(config_dir.glob("*.bed"))
    if len(bed) != 1:
        logger.error(f"ERROR: No or >1 capture bed file found for sample {wildcards.sample} - {bed}")
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

    targets = (
        expand(
            [
                PROJECT_PATH / "{{sample}}" / "qc" / "fastqc-raw" / "{{sample}}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{{sample}}" / "qc" / "fastqc-trimmed" / "{{sample}}-{unit}-{read}_fastqc.zip",
                PROJECT_PATH / "{{sample}}" / "qc" / "fastq_screen-trimmed" / "{{sample}}-{unit}-{read}_screen.txt",
                PROJECT_PATH / "{{sample}}" / "qc" / "dedup" / "{{sample}}-{unit}.metrics.txt",
            ],
            unit=units,
            read=["R1", "R2"],
        ),
    )

    return targets[0]


##########################   Configs from CLI  ##########################
OUT_DIR = Path(config["out_dir"])
PROJECT_NAME = config["project_name"]
PROJECT_PATH = Path(config["projects_path"]) / PROJECT_NAME / "analysis"
PEDIGREE_FPATH = config["ped"]
EXOME_MODE = config["exome"]
ALLOW_SAMPLE_RENAMING = config["allow_sample_renaming"]
INCLUDE_PRIOR_QC_DATA = config["include_prior_qc_data"]

#### configs from configfile ####
RULE_LOGS_PATH = Path(config["log_dir"]) / "rule_logs"
RULE_LOGS_PATH.mkdir(parents=True, exist_ok=True)

SAMPLES = get_samples(PEDIGREE_FPATH)
MULTIQC_CONFIG_FILE = OUT_DIR / "project_level_qc" / "multiqc" / "configs" / f"tmp_multiqc_config-{config['unique_id']}.yaml"

logger.info(f"// Processing project: {PROJECT_NAME}")
logger.info(f'// Project path: "{PROJECT_PATH}"')
logger.info(f"// Exome mode: {EXOME_MODE}")
logger.info(f"// Include prior QC data: {INCLUDE_PRIOR_QC_DATA}")
