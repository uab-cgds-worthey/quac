import csv
import re
from pathlib import PurePath
from snakemake.logging import logger
import pandas as pd


# TODO: refactor to import from src/read_sample_config.py
def read_sample_config(config_f):
    "read sample config file and return map of samples to their input filepaths"

    with open(config_f) as fh:
        csv_reader = csv.DictReader(fh, delimiter="\t")

        samples_dict = {}
        for row in csv_reader:
            bam = row["bam"]
            vcf = row["vcf"]
            
            fastq = {}
            for unit in row["fastq"].split(";"):
                unit = unit.strip().split(",")
                if unit[0] in fastq:
                    print(f"ERROR: Fastq unit '{unit[0]}' for '{sample}' found >1x in config file '{config_f}'")
                    raise SystemExit(1)

                fastq[unit[0]] = {"R1": unit[1], "R2": unit[2]}

            sample = row["sample_id"].strip(" ")
            if sample in samples_dict:
                print(f"ERROR: Sample '{sample}' found >1x in config file '{config_f}'")
                raise SystemExit(1)

            samples_dict[sample] = {"vcf": vcf, "bam": bam, "fastq": fastq}

            # expect only filepath per field
            for colname in ["capture_bed"]:
                if colname in row:
                    samples_dict[sample][colname] = row[colname]
                    
            # expect >=1 filepath per field
            for colname in ["dedup"]:
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

    column_list = ["dedup"]
    file_list = []
    for column in column_list:
        file_list.append(samples_dict[sample][column])

    flat_filelist = [item for sublist in file_list for item in sublist]

    return flat_filelist


def get_basename_stem(filepath):
    "removes fastq extensions from filepath and returns basename"

    basename = os.path.basename(filepath)

    if basename.endswith('.gz'):
        basename = basename[:-3]

    if basename.endswith('.fastq'):
        basename = basename[:-6]

    if basename.endswith('.fq'):
        basename = basename[:-3]

    return basename


def write_sample_rename_config(filepath, sample, samples_config):
    "provides sensible sample names for fastq files, to use in multiqc. Saved into tsv file."

    with open(filepath, "w") as f_handle:
        f_handle.write('\t'.join(['Original labels', 'Renamed labels']) + '\n')
        for unit in samples_config[sample]["fastq"]:
            base_rename = f"{sample}-{unit}"

            f_handle.write('\t'.join([get_basename_stem(samples_config[sample]["fastq"][unit]["R1"]), f"{base_rename}-R1"]) + '\n')
            f_handle.write('\t'.join([get_basename_stem(samples_config[sample]["fastq"][unit]["R2"]), f"{base_rename}-R2"]) + '\n')

    return None

##########################   Configs from CLI  ##########################
OUT_DIR = Path(config["out_dir"])
PEDIGREE_FPATH = config["ped"]
EXOME_MODE = config["exome"]
INCLUDE_PRIOR_QC_DATA = config["include_prior_qc_data"]

SAMPLES_CONFIG = read_sample_config(config["sample_config"])
SAMPLES = list(SAMPLES_CONFIG.keys())

# subdir where project level QC results will be written
if "project_level_qc_dir" in config and config["project_level_qc_dir"]:
    PROJECT_LEVEL_QC_SUBDIR = config["project_level_qc_dir"]
else:
    PROJECT_LEVEL_QC_SUBDIR = "project_level_qc"

#### configs from configfile ####
RULE_LOGS_PATH = Path(config["log_dir"]) / "rule_logs"
RULE_LOGS_PATH.mkdir(parents=True, exist_ok=True)

MULTIQC_CONFIG_FILE = OUT_DIR / PROJECT_LEVEL_QC_SUBDIR / "multiqc" / "configs" / f"tmp_multiqc_config-{config['unique_id']}.yaml"

logger.info(f"// Sample configfile: {config['sample_config']}")
logger.info(f'// Output directory: "{OUT_DIR}"')
logger.info(f"// Exome mode: {EXOME_MODE}")
logger.info(f"// Include prior QC data: {INCLUDE_PRIOR_QC_DATA}")
