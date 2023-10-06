import csv
import re
from pathlib import PurePath
from snakemake.logging import logger


# TODO: refactor to import from src/read_sample_config.py
def read_sample_config(config_f):
    "read sample config file and return map of samples to their input filepaths"

    with open(config_f) as fh:
        csv_reader = csv.DictReader(fh, delimiter="\t")

        samples_dict = {}
        for row in csv_reader:
            bam = row["bam"]
            vcf = row["vcf"]

            sample = row["sample_id"].strip(" ")
            if sample in samples_dict:
                print(f"ERROR: Sample '{sample}' found >1x in config file '{config_f}'")
                raise SystemExit(1)

            samples_dict[sample] = {"vcf": vcf, "bam": bam}

            for colname in ["capture_bed"]:
                if colname in row:
                    samples_dict[sample][colname] = row[colname]

    return samples_dict


def is_testing_mode():
    "checks if testing dataset is used as input for the pipeline"

    query = ".test"
    for sample in SAMPLES_CONFIG.values():
        for fpath in sample.values():
            if query in PurePath(fpath).parts:
                logger.info(f"// WARNING: '{query}' present in at least one of the filepaths supplied via --sample_config. So testing mode is used.")
                return True

    return None


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
PEDIGREE_FPATH = config["ped"]
EXOME_MODE = config["exome"]
ALLOW_SAMPLE_RENAMING = config["allow_sample_renaming"]
INCLUDE_PRIOR_QC_DATA = config["include_prior_qc_data"]

SAMPLES_CONFIG = read_sample_config(config["sample_config"])
SAMPLES = list(SAMPLES_CONFIG.keys())

#### configs from configfile ####
RULE_LOGS_PATH = Path(config["log_dir"]) / "rule_logs"
RULE_LOGS_PATH.mkdir(parents=True, exist_ok=True)

MULTIQC_CONFIG_FILE = OUT_DIR / "project_level_qc" / "multiqc" / "configs" / f"tmp_multiqc_config-{config['unique_id']}.yaml"

logger.info(f"// Sample configfile: {config['sample_config']}")
logger.info(f'// Output directory: "{OUT_DIR}"')
logger.info(f"// Exome mode: {EXOME_MODE}")
logger.info(f"// Include prior QC data: {INCLUDE_PRIOR_QC_DATA}")
