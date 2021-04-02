"""
Reads multiqc general stats file
"""

import pandas as pd
from common import qc_logger

# setup logging
LOGGER = qc_logger(__name__)


def read_stats(filepath):

    LOGGER.info(f"Reading multiqc general stats file: {filepath}")
    df = pd.read_csv(filepath, sep="\t", index_col="Sample")

    return df
