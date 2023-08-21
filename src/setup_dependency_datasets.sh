#!/usr/bin/env bash
set -euo pipefail

echo "This script retrieves necessary dataset dependencies for Quac."

PARENT_DIR=$(dirname $(realpath -s $0))
DATA_DIR="${PARENT_DIR}/../data/external/dependency_datasets"
mkdir -p $DATA_DIR && cd $DATA_DIR
echo "Datasets will be saved in '$DATA_DIR'"

##### retrieve reference genome #####
echo "setting up reference genome data..."
REF_GENOME_DIR="${DATA_DIR}/reference_genome"
mkdir -p $REF_GENOME_DIR && cd $REF_GENOME_DIR

REF_GENOME_FNAME="GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"
REF_GENOME_URL=ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/${REF_GENOME_FNAME}
curl -L $REF_GENOME_URL -o $REF_GENOME_FNAME
gzip -c $REF_GENOME_FNAME >$(basename $REF_GENOME_FNAME .gz)

##### retrieve somalier tool dependencies #####
echo "setting up somalier dependency datasets..."
SOMALIER_DIR="${DATA_DIR}/somalier"
mkdir -p $SOMALIER_DIR && cd $SOMALIER_DIR

curl -L -O "https://github.com/brentp/somalier/files/3412456/sites.hg38.vcf.gz"
curl -L -O "https://raw.githubusercontent.com/brentp/somalier/master/scripts/ancestry-labels-1kg.tsv"
curl -L -O "https://zenodo.org/record/3479773/files/1kg.somalier.tar.gz"
tar xzf "1kg.somalier.tar.gz"

##### retrieve VerifyBamID tool dependencies #####
echo "setting up VerifyBamID dependency datasets..."
VBID_DIR="${DATA_DIR}/verifyBamID"
mkdir -p $VBID_DIR && cd $VBID_DIR

VERIFYBAMID_SOURCE_URL="https://raw.githubusercontent.com/Griffan/VerifyBamID/2.0.1"

# genome data
for FILE_EXT in bed mu UD V; do
    curl -L -O ${VERIFYBAMID_SOURCE_URL}/resource/1000g.phase3.100k.b38.vcf.gz.dat.${FILE_EXT}
done

# exome data. Include "chr" prefix to contigs
mkdir -p exome && cd exome
curl -L ${VERIFYBAMID_SOURCE_URL}/resource/exome/1000g.phase3.10k.b38.exome.vcf.gz.dat.bed | sed -e 's/^/chr/' - >1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.bed
curl -L ${VERIFYBAMID_SOURCE_URL}/resource/exome/1000g.phase3.10k.b38.exome.vcf.gz.dat.mu | sed -e 's/^/chr/' - >1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.mu
curl -L ${VERIFYBAMID_SOURCE_URL}/resource/exome/1000g.phase3.10k.b38.exome.vcf.gz.dat.UD >1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.UD
curl -L ${VERIFYBAMID_SOURCE_URL}/resource/exome/1000g.phase3.10k.b38.exome.vcf.gz.dat.V >1000g.phase3.10k.b38_chr.exome.vcf.gz.dat.V
