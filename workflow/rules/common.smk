def get_samples(ped_fpath):
    """
    Parse pedigree file and return sample names
    """

    samples = ()
    with open(ped_fpath, 'r') as f_handle:
        for line in f_handle:
            if line.startswith('#'):
                continue
            sample = line.split('\t')[1]
            samples += (sample,)

    return samples


def modules_to_run(user_input):
    """
    Parse user-selected tools. Verify they are among the expected values.
    """
    user_input = set([x.strip().lower() for x in user_input.strip().split(',')])

    allowed_options=['somalier', 'verifybamid', 'indexcov', 'mosdepth', 'covviz', 'all']
    if user_input.difference(set(allowed_options)):
        msg =f"ERROR: Unexpected module was supplied by user. Allowed options: {allowed_options}"
        raise SystemExit(msg)

    print (f"Tools chosen by user to run: {list(user_input)}")

    return user_input


def get_targets(tool_name, samples=None):
    """
    returns target files based on the tool
    """


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
        flist += [OUT_DIR / "mosdepth" / f"mosdepth.html"]
        flist += expand(str(OUT_DIR / "mosdepth" / "results" / "{sample}.mosdepth.global.dist.txt"),
                    sample=samples),
    elif tool_name == 'verifybamid':
        flist += expand(str(OUT_DIR / "verifyBamID" / "{sample}.Ancestry"),
                    sample=samples),

    return flist


#### configs from cli ####
OUT_DIR = Path(config['out_dir'])
PROJECT_NAME = config['project_name']
MODULES_TO_RUN = modules_to_run(config['modules'])
PEDIGREE_FPATH = config['ped']

#### configs from configfile ####
PROJECTS_PATH = Path(config['projects_path'])
LOGS_PATH = Path(config['logs_path'])
LOGS_PATH.mkdir(parents=True, exist_ok=True)

SAMPLES = get_samples(PEDIGREE_FPATH)
