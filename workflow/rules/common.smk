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


#### configs from cli ####
OUT_DIR = Path(config["out_dir"])
PROJECT_NAME = config["project_name"]
PROJECT_PATH = Path(config["projects_path"]) / PROJECT_NAME
PEDIGREE_FPATH = config["ped"]
EXOME_MODE = config["exome"]

#### configs from configfile ####
RULE_LOGS_PATH = Path(config["log_dir"]) / "rule_logs"
RULE_LOGS_PATH.mkdir(parents=True, exist_ok=True)

SAMPLES = get_samples(PEDIGREE_FPATH)
