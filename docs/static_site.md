# Read the Docs for hosting

[mkdocs](https://www.mkdocs.org/) is used to serve up the static website, and [Read the
Docs](https://docs.readthedocs.io/) is used for hosting it online.

## Use mkdocs for development

mkdocs can be used in the local machine during development to test website is building correctly. Commands used:

```sh
# create  conda env
conda env create --file "configs/mkdocs/mkdocs.yaml"

# activate env
conda activate mkdocs

# install more stuff via pip (not ideal but good enough for now)
pip install -r "configs/mkdocs/requirements.txt"

# now build website using website and serve live (locally)
mkdocs serve
```
