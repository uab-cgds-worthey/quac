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


OUT_DIR = Path(config['out_dir'])

LOGS_PATH = Path(config['logs_path'])
LOGS_PATH.mkdir(parents=True, exist_ok=True)

PROJECTS_PATH = Path(config['projects_path'])
PROJECT_NAME = config['project_name']
PEDIGREE_FPATH = config['ped']
SAMPLES = get_samples(PEDIGREE_FPATH)

MODULES_TO_RUN = modules_to_run(config['modules'])


def get_targets(tool_name, project=PROJECT_NAME, samples=SAMPLES):

    flist = []
    if tool_name == 'somalier':
        flist += [
            OUT_DIR / "somalier" / "relatedness" / "somalier.html",
            OUT_DIR / "somalier" / "ancestry" / "somalier.somalier-ancestry.html"
            ]
    elif tool_name == 'indexcov':
        flist += [OUT_DIR / "indexcov" / "index.html"]
    elif tool_name == 'covviz':
        flist += [OUT_DIR / "covviz/" / "covviz_report.html"]
    elif tool_name == 'mosdepth':
        flist += [OUT_DIR / "mosdepth" / f"mosdepth_{PROJECT_NAME}.html"]
        flist += expand(str(OUT_DIR / "mosdepth" / "results" / "{sample}.mosdepth.global.dist.txt"),
                    sample=SAMPLES),
    elif tool_name == 'verifybamid':
        flist += expand(str(OUT_DIR / "verifyBamID" / "{sample}.Ancestry"),
                    sample=SAMPLES),


    return flist
