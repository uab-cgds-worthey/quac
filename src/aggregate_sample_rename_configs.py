"""
Read multiple sample renaming config files and output them all in to a single file
"""

import fire

def main(infile, outfile):

    header_string = "Original labels\tRenamed labels"
    aggregated_data = [header_string]
    
    with open(infile, "r") as in_handle:
        for fpath in in_handle:
            with open(fpath.strip()) as fh:
                for line_no, line in enumerate(fh):
                    line = line.strip("\n")

                    if not line_no:
                        if line != "Original labels\tRenamed labels":
                            print(f"Error: Unexpected header string in file '{fpath}'")
                            raise SystemExit(1)
                    else:
                        aggregated_data.append(line)

    with open(outfile, "w") as out_handle:
        out_handle.write("\n".join(aggregated_data))

    return None


if __name__=="__main__":
    FIRE_MODE = True
    # FIRE_MODE = False

    if FIRE_MODE:
        fire.Fire(main)
    else:
        INFILE=""
        OUTFILE=""
        main(INFILE, OUTFILE)