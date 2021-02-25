from pathlib import Path
import csv


def get_haplocheck_results(fpath):

    with open(fpath) as f_handle:
        for row in csv.DictReader(f_handle, delimiter="\t"):
            cont_status, cont_level = row["Contamination Status"], row["Contamination Level"]
            # print(type(cont_level), cont_level)
            # cont_level = float(cont_level) * 100 if cont_level != "ND" else cont_level
            if cont_level != "ND":
                # print(cont_level, float(cont_level))
                cont_level = float(cont_level) * 100
            return cont_status, str(cont_level)


def get_verifyBamID_results(fpath):

    with open(fpath) as f_handle:
        for row in csv.DictReader(f_handle, delimiter="\t"):
            cont_level = float(row["FREEMIX"]) * 100
            return str(cont_level)


def main(in_dir, project_name, outfile):

    haplocheck_dir = Path(in_dir) / "haplocheck" / project_name
    verifyBamID_dir = Path(in_dir) / "verifyBamID" / project_name

    samples = (
        f.name for f in haplocheck_dir.iterdir() if f.is_dir() and f.name.startswith(("LW", "UDN"))
    )

    with open(outfile, "w") as out_handle:
        out_handle.write(
            "\t".join(
                [
                    "sample_id",
                    "haplocheck_contamination_status",
                    "haplocheck_contamination_level (%)",
                    "verifyBamID_contamination_level (%)",
                ]
            )
            + "\n"
        )

        for sample in samples:
            haplocheck_f = haplocheck_dir / sample / "haplocheck.txt"
            verifyBamID_f = verifyBamID_dir / f"{sample}.selfSM"

            hc_cont_status, hc_cont_level = get_haplocheck_results(haplocheck_f)
            vb_cont_level = get_verifyBamID_results(verifyBamID_f)

            out_handle.write(
                "\t".join([sample, hc_cont_status, hc_cont_level, vb_cont_level]) + "\n"
            )

        # break

    return None


if __name__ == "__main__":
    IN_DIR = "/data/project/worthey_lab/projects/experimental_pipelines/mana/quac/data/processed"
    PROJECT_NAME = "MuscDyst_SU_MAlexander"

    for PROJECT_NAME in [
        "CF_TLOAF_PFarrell",
        "CF_CFF_PFarrell",
        "EDS3_unkn_DGreenspan",
        "MuscDyst_SU_MAlexander",
        "UDN_Phase1_EAWorthey",
    ]:
        OUTFILE = f"delete-{PROJECT_NAME}.tsv"
        main(IN_DIR, PROJECT_NAME, OUTFILE)
