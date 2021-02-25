"""
Create dummy ped file by project

Usage:
ml reset
ml Anaconda3
conda activate quac_common
python src/create_dummy_ped.py
"""

from pathlib import Path
import pandas as pd


def read_project_tracker(project_tracker_f):

    df = pd.read_excel(project_tracker_f, usecols=["CGDS ID", "Sex"])

    df["sex_ped"] = df["Sex"].str.lower().map({"m": "1", "f": "2"})
    df["sex_ped"] = df["sex_ped"].fillna("-9")  # unknown sex

    sample_sex_dict = df.set_index("CGDS ID")["sex_ped"].to_dict()

    return sample_sex_dict


def nbbbb():

    project_path = Path("/data/project/worthey_lab/projects") / project_name / "analysis"
    samples = (
        f.name for f in project_path.iterdir() if f.is_dir() and f.name.startswith(("LW", "UDN"))
    )

    header = ["#family_id", "sample_id", "paternal_id", "maternal_id", "sex", "phenotype"]
    with open(Path(outpath) / f"{project_name}.ped", "w") as out_handle:
        out_handle.write("\t".join(header) + "\n")

        for sample in sorted(samples):
            data = ["unknown", sample, "-9", "-9", "-9", "-9"]
            out_handle.write("\t".join(data) + "\n")

    return None


def main(outpath):

    project_dict = {
        "CF_CFF_PFarrell": {
            "tracking_sheet": "data/external/project_tracker/PROJECT TRACKING -CF.xlsx",
            "affected": "all",
        },
        "CF_TLOAF_PFarrell": {
            "tracking_sheet": "data/external/project_tracker/PROJECT TRACKING -CF.xlsx",
            "affected": "all",
        },
        # "CF_TLOAF_PFarrell",
        # "EDS3_unkn_DGreenspan",
        # "MuscDyst_SU_MAlexander",
        # "UDN_Phase1_EAWorthey",
    }

    for project_name in project_dict:
        # get sample's sex info from project tracking sheet
        sample_sex_dict = read_project_tracker(project_dict[project_name]["tracking_sheet"])

        # get samples from cheaha for the project
        project_path = Path("/data/project/worthey_lab/projects") / project_name / "analysis"
        samples = (
            f.name
            for f in project_path.iterdir()
            if f.is_dir() and f.name.startswith(("LW", "UDN"))
        )

        header = ["#family_id", "sample_id", "paternal_id", "maternal_id", "sex", "phenotype"]
        with open(Path(outpath) / f"{project_name}.ped", "w") as out_handle:
            out_handle.write("\t".join(header) + "\n")

            for sample in sorted(samples):
                data = [
                    "unknown",
                    sample,
                    "-9",  # father
                    "-9",  # mother
                    sample_sex_dict[sample],  # sample sex
                    "1" if project_dict[project_name]["affected"] == "all" else "-9",  # affected
                ]
                out_handle.write("\t".join(data) + "\n")

    return None


if __name__ == "__main__":
    OUT_PATH = "data/raw/ped"  # not so raw, is it?
    main(OUT_PATH)
