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
        print(f"ERROR: File provided in sample config file was not found: '{fpath}'")
        raise SystemExit(1)

    return get_full_path(fpath)


def read_sample_config(config_f):

    with open(config_f) as fh:
        csv_reader = csv.DictReader(fh, delimiter="\t")
        colnames = csv_reader.fieldnames

        samples_dict = {}
        for row in csv_reader:
            bam = is_valid_file(row["bam"])
            vcf = is_valid_file(row["vcf"])

            sample = row["sample_id"].strip(" ")
            if sample in samples_dict:
                print(f"ERROR: Sample '{sample}' found >1x in config file '{config_f}'")
                raise SystemExit(1)

            samples_dict[sample] = {"vcf": vcf, "bam": bam}

            # expect only filepath per field
            for colname in ["capture_bed", "multiqc_rename_config"]:
                if colname in row:
                    samples_dict[sample][colname] = is_valid_file(row[colname])

            # expect >=1 filepath per field
            for colname in ["dedup"]:
                if colname in row:
                    samples_dict[sample][colname] = [
                        is_valid_file(f) for f in row[colname].split(",")
                    ]

            # specially formatted as "unit #,fq-read-1-path,fq-read-2-path;unit #,fq-read-1-path,fq-read-2-path;..."
            for colname in ["fastq"]:
                if colname in row:
                    samples_dict[sample][colname] = []
                    # aggregate the fastq file paths into a single list, ignore unit number
                    # b/c it can be infered by list ordering if needed
                    for fq_unit in row[colname].split(";"):
                        fq_unit_info = fq_unit.strip().split(",")
                        for f in fq_unit_info[1:]:
                            samples_dict[sample][colname].append(is_valid_file(f))

    return samples_dict, colnames


if __name__ == "__main__":
    SAMPLES_CONFIG_F = ".test/configs/no_priorQC/sample_config/project_2samples.tsv"
    read_sample_config(SAMPLES_CONFIG_F)
