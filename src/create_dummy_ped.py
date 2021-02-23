"""
Create dummy ped file by project
"""

from pathlib import Path


def main(project_name, outpath):

    project_path = Path("/data/project/worthey_lab/projects") / project_name / "analysis"

    samples = (
        f.name for f in project_path.iterdir() if f.is_dir() and f.name.startswith(("LW", "UDN"))
    )

    header = ["#family_id", "sample_id", "paternal_id", "maternal_id", "sex", "phenotype"]
    with open(Path(outpath) / f"{project_name}.ped", "w") as out_handle:
        out_handle.write("\t".join(header) + "\n")

        for sample in samples:
            data = ["unknown", sample, "-9", "-9", "-9", "-9"]
            out_handle.write("\t".join(data) + "\n")

    return None


if __name__ == "__main__":
    OUT_PATH = "data/raw/ped"  # not so raw, is it?
    # PROJECT_NAME = "MuscDyst_SU_MAlexander"
    for PROJECT_NAME in [
        "CF_TLOAF_PFarrell",
        "CF_CFF_PFarrell",
        "EDS3_unkn_DGreenspan",
        "MuscDyst_SU_MAlexander",
        "UDN_Phase1_EAWorthey",
    ]:
        main(PROJECT_NAME, OUT_PATH)
