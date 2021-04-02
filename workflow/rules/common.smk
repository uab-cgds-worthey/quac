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
