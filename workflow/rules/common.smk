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
PROJECT_NAME = config['project_name']
SAMPLES = get_samples(RAW_DIR / f"ped/{PROJECT_NAME}.ped")

MODULES_TO_RUN = modules_to_run(config['modules'])


def get_targets(tool_name, project=PROJECT_NAME, samples=SAMPLES):

    flist = []
    if tool_name == 'somalier':
        flist += expand(str(PROCESSED_DIR / "somalier/{project}/relatedness/somalier.html"),
                    project=[PROJECT_NAME]),
        flist += expand(str(PROCESSED_DIR / "somalier/{project}/ancestry/somalier.somalier-ancestry.html"),
                    project=[PROJECT_NAME]),
    elif tool_name == 'indexcov':
        flist += expand(str(PROCESSED_DIR / "indexcov/{project}/index.html"),
                    project=[PROJECT_NAME])
    elif tool_name == 'covviz':
        flist += expand(str(PROCESSED_DIR / "covviz/{project}/covviz_report.html"),
                    project=[PROJECT_NAME]),
    elif tool_name == 'mosdepth':
        flist += expand(str(PROCESSED_DIR / "mosdepth/{project}/mosdepth_{project}.html"),
                    project=[PROJECT_NAME]),
        flist += expand(str(PROCESSED_DIR / "mosdepth/{project}/results/{sample}.mosdepth.global.dist.txt"),
                    project=[PROJECT_NAME],
                    sample=SAMPLES),
    elif tool_name == 'verifybamid':
        flist += expand(str(PROCESSED_DIR / "verifyBamID/{project}/{sample}.Ancestry"),
                    project=[PROJECT_NAME],
                    sample=SAMPLES),


    return flist
