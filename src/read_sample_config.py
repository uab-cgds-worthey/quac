"""
Read user sample config file, verify filepaths exist and return dictionary
"""

from pathlib import Path
import csv


def get_full_path(x):
    full_path = Path(x).resolve()

    return str(full_path)


def is_valid_file(fpath):
    if not Path(fpath).is_file():
        print(f"File provided in sample config file was not found: {fpath}")
        raise SystemExit(1)

    return get_full_path(fpath)


def read_sample_config(config_f):

    with open(config_f) as fh:
        csv_reader = csv.DictReader(fh, delimiter="\t")

        samples_dict = {}
        for row in csv_reader:
            bam = is_valid_file(row["bam"])
            vcf = is_valid_file(row["vcf"])

            sample = row["sample_id"].strip(" ")
            if sample in samples_dict:
                print(f"ERROR: Sample '{sample}' found >1x in config file '{config_f}'")
                raise SystemExit(1)

            samples_dict[sample] = {"vcf": vcf, "bam": bam}

    return samples_dict


if __name__ == "__main__":
    SAMPLES_CONFIG_F = ".test/configs/no_priorQC/sample_config/project_2samples.tsv"
    read_sample_config(SAMPLES_CONFIG_F)