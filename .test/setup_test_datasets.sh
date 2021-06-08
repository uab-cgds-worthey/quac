#!/usr/bin/env bash
set -euo pipefail

# This script sets up test bam and vcf datasets using NA12878 sample, which was run
# through CGDS's small variant caller pipeline.
# Also creates test capture-region bed file.

module reset
module load SAMtools/1.9-GCC-6.4.0-2.28
module load HTSlib/1.9-GCC-6.4.0-2.28

############# bam files #############

echo "Setting up test bam files..."

NA12878_BAM="/data/project/worthey_lab/samples/NA12878/analysis/bam/NA12878.bam"
SUBSAMPLED_BAM="tmp.bam"
TARGET_REGION="chr20:59993-3653078"
samtools view -s 0.03 -b $NA12878_BAM $TARGET_REGION > $SUBSAMPLED_BAM

PROJECT_DIR="ngs-data/test_project/analysis"
for sample in A B; do
    ### bams ###
    BAM_DIR="${PROJECT_DIR}/${sample}/bam"
    mkdir -p $BAM_DIR
    OUT_BAM=${BAM_DIR}/${sample}.bam

    # reheader_bam $TMP_BAM_2 $sample $OUT_BAM

    echo "change sample name in bam"
    samtools view -H $SUBSAMPLED_BAM  \
        | sed "s/SM:[^\t]*/SM:${sample}/g" \
        | samtools reheader - $SUBSAMPLED_BAM \
        > $OUT_BAM
    samtools index $OUT_BAM
done

# clean up yo
rm -f $SUBSAMPLED_BAM


############# VCF files #############

echo "Setting up test vcf files..."
NA12878_VCF="/data/project/worthey_lab/samples/NA12878/analysis/small_variants/na12878.vcf.gz"

for sample in A B; do
    VCF_DIR="${PROJECT_DIR}/${sample}/vcf"
    mkdir -p $VCF_DIR
    OUT_vcf=${VCF_DIR}/${sample}.vcf.gz

    tabix -h $NA12878_VCF $TARGET_REGION \
        | bgzip > $OUT_vcf
    tabix $OUT_vcf
done


############# Regions file #############

# Treat sample B as exome dataset and add a capture-regions bed file
CAPTURE_FILE="${PROJECT_DIR}/B/configs/small_variant_caller/capture_regions.bed"
mkdir -p $(dirname $CAPTURE_FILE)
echo -e "chr20\t59992\t3653078\n" > $CAPTURE_FILE
