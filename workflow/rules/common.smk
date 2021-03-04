def get_samples(ped_fpath):

    samples = ()
    with open(ped_fpath, 'r') as f_handle:
        for line in f_handle:
            if line.startswith('#'):
                continue
            sample = line.split('\t')[1]
            samples += (sample,)

    return samples


def modules_to_run(chosen, allowed_options=['somalier', 'verifybamid', 'indexcov', 'mosdepth', 'covviz', 'all']):

    selected_modules = set([x.strip().lower() for x in chosen.strip().split(',')])
    if selected_modules.difference(set(allowed_options)):
        msg =f"ERROR: Unexpected module was supplied by user. Allowed options: {allowed_options}"
        raise SystemExit(msg)

    return selected_modules


EXTERNAL_DIR = Path("data/external")
RAW_DIR = Path("data/raw")
INTERIM_DIR = Path("data/interim")
PROCESSED_DIR = Path("data/processed")

LOGS_PATH = Path(config['logs_path'])
LOGS_PATH.mkdir(parents=True, exist_ok=True)

PROJECTS_PATH = Path(config['projects_path'])
PROJECT_NAMES = config['project_names'].split(',')
SAMPLES = {project: get_samples(RAW_DIR / f"ped/{project}.ped") for project in PROJECT_NAMES}

MODULES_TO_RUN = modules_to_run(config['modules'])


def get_targets(tool_name, projects=PROJECT_NAMES, sample_dict=SAMPLES):

    flist = []
    for project in projects:
        for sample in sample_dict[project]:
            if tool_name == 'mosdepth':
                f = INTERIM_DIR / "mosdepth" / project / f"{sample}.mosdepth.global.dist.txt"
                flist.append(f)
            elif tool_name == 'verifybamid':
                f = PROCESSED_DIR / "verifyBamID" / project / f"{sample}.Ancestry"
                flist.append(f)

        if tool_name == 'somalier':
            f = [
                expand(str(PROCESSED_DIR / "somalier/{project}/relatedness/somalier.html"),
                    project=PROJECT_NAMES),
                expand(str(PROCESSED_DIR / "somalier/{project}/ancestry/somalier.somalier-ancestry.html"),
                    project=PROJECT_NAMES),
            ]
            flist.append(f)
        elif tool_name == 'indexcov':
            f = expand(str(PROCESSED_DIR / "indexcov/{project}/index.html"),
                    project=PROJECT_NAMES)
            flist.append(f)
        elif tool_name == 'covviz':
            f = expand(str(PROCESSED_DIR / "covviz/{project}/covviz_report.html"),
                    project=PROJECT_NAMES),
            flist.append(f)
        elif tool_name == 'mosdepth':
            f = expand(str(PROCESSED_DIR / "mosdepth/{project}/mosdepth_{project}.html"),
                    project=PROJECT_NAMES),
            flist.append(f)


    return flist
