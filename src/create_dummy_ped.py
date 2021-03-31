"""
Create dummy ped file by project

Usage:
# setup environment
ml reset
ml Anaconda3
conda activate quac_common

# Example
python src/create_dummy_ped.py --project_path "/data/project/worthey_lab/projects/CF_CFF_PFarrell/" --outfile test.ped
"""

from pathlib import Path
import pandas as pd
import fire


def read_project_tracker(project_tracker_f):
    """
    Reads project tracking excel file. Expects certain columns to be present.
    """

    df = pd.read_excel(project_tracker_f, usecols=["CGDS ID", "Sex"])

    df["sex_ped"] = df["Sex"].str.lower().map({"m": "1", "f": "2"})
    df["sex_ped"] = df["sex_ped"].fillna("-9")  # unknown sex

    sample_sex_dict = df.set_index("CGDS ID")["sex_ped"].to_dict()

    return sample_sex_dict


def main(project_path, outfile, tracking_sheet=False):
    """
    Creates dummy pedigree file for the project requested

    Args:
        project_path (str): Project path. Script will look for samples under its subdirectory "analysis".
        outfile (str): Output pedigree file path
        tracking_sheet (str, optional): Project tracking sheet in excel format. Uses this for sex info. Defaults to False.
    """

    # get sample's sex info from project tracking sheet, if supplied
    if tracking_sheet:
        sample_sex_dict = read_project_tracker(tracking_sheet)

    # get samples from cheaha for the project
    project_path = Path(project_path) / "analysis"
    samples = (
        f.name for f in project_path.iterdir() if f.is_dir() and f.name.startswith(("LW", "UDN"))
    )

    header = ["#family_id", "sample_id", "paternal_id", "maternal_id", "sex", "phenotype"]
    with open(outfile, "w") as out_handle:
        out_handle.write("\t".join(header) + "\n")

        for sample in sorted(samples):
            data = [
                "unknown",
                sample,
                "-9",  # father
                "-9",  # mother
                sample_sex_dict[sample] if tracking_sheet else "-9",  # sample sex
                "-9",  # affected
            ]
            out_handle.write("\t".join(data) + "\n")

    return None


if __name__ == "__main__":
    FIRE_MODE = True
    # FIRE_MODE = False

    if FIRE_MODE:
        fire.Fire(main)
    else:
        PROJECT_PATH = "/data/project/worthey_lab/projects/CF_CFF_PFarrell/"
        OUTFILE = "out.ped"
        main(PROJECT_PATH, OUTFILE)
