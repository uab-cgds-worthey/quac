"""
This script verifies singularity works as expected. 
Uses a basic "singularity run" command for this testing.
"""

import subprocess


def test_singularity():

    cmd = "singularity run library://sylabsed/examples/lolcow"
    result = subprocess.run(
        cmd.split(" "),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
    )
    if result.returncode != 0:
        print(
            "Test was performed to check Singularity was working as expected but it ran into error."
            " Please make sure singularity works as expected before using QuaC."
        )
        print(f"Command ran: '{cmd}'")
        print(f"Error message:\n{result.stdout}")
        raise SystemExit(1)

    return None


if __name__ == "__main__":

    test_singularity()
