# FAQ

## QuaC workflow failed due to `Error: Directory cannot be locked`

See [snakemake docs
here](https://snakemake.readthedocs.io/en/stable/project_info/faq.html#how-does-snakemake-lock-the-working-directory) on
why snakemake locks the working directory. `Error: Directory cannot be locked` might happen when the parent snakemake
process gets killed unexpectedly before completion. It is recommended to investigate why it got killed before proceeding
to the next step. If you want to remove the lock (ie. unlock it), add `-e='--unlock'` to your original run
`src/run_quac.py` command. Once that has completed you can run the original command again and the pipeline will pick up
from it's last state.
