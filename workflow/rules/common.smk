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

            # expect only filepath per field
            for colname in ["capture_bed", "multiqc_rename_config"]:
                if colname in row:
                    samples_dict[sample][colname] = row[colname]
                    
            # expect >=1 filepath per field
            for colname in ["fastqc_raw", "fastq_screen", "dedup"]:
                if colname in row:
                    samples_dict[sample][colname] = row[colname].split(",")

    return samples_dict


def is_testing_mode():
    "checks if testing dataset is used as input for the pipeline"

    query = ".test"
    isTesting = False
    for sample in SAMPLES_CONFIG.values():
        for fvalue in sample.values():
            if isinstance(fvalue, str) and query in PurePath(fvalue).parts:
                isTesting = True
            else:
                for fpath in fvalue:
                    if query in PurePath(fpath).parts:
                        isTesting = True

    if isTesting:
        logger.info(f"// WARNING: '{query}' present in at least one of the filepaths supplied via --sample_config. So testing mode is used.")
        return True

    return None


def get_priorQC_filepaths(sample, samples_dict):
    """
    Returns filepaths relevant to priorQC
    """

    column_list = ["fastqc_raw", "fastq_screen", "dedup"]
    file_list = []
    for column in column_list:
        file_list.append(samples_dict[sample][column])

    flat_filelist = [item for sublist in file_list for item in sublist]

    return flat_filelist


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
