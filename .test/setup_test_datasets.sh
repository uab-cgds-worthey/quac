#!/usr/bin/env bash
set -euo pipefail

# This script sets up test bam and vcf files
# For test bam, it uses bam dataset provided by verifybamid
# For test vcf, it uses bam dataset provided by somalier

module reset
module load SAMtools/1.9-GCC-6.4.0-2.28
module load HTSlib/1.9-GCC-6.4.0-2.28

############# bam files #############

echo "Download test bam file verifybamid repo"
TMP_BAM_1="tmp1.bam"
TMP_BAM_2="tmp2.bam"
curl -L https://github.com/Griffan/VerifyBamID/raw/2.0.1/resource/test/test.bam \
    -o "${TMP_BAM_1}"


echo "rename header to use chr contig naming"
samtools view -H $TMP_BAM_1 > header.txt
sed -i -e 's/SN:/SN:chr/g' header.txt
samtools reheader header.txt $TMP_BAM_1 > $TMP_BAM_2


PROJECT_DIR="ngs-data/test_project/analysis"
for sample in A B; do
    ### bams ###
    BAM_DIR="${PROJECT_DIR}/${sample}/bam"
    mkdir -p $BAM_DIR
    OUT_BAM=${BAM_DIR}/${sample}.bam

    # reheader_bam $TMP_BAM_2 $sample $OUT_BAM

    echo "change sample name in bam"
    samtools view -H $TMP_BAM_2  \
        | sed "s/SM:[^\t]*/SM:${sample}/g" \
        | samtools reheader - $TMP_BAM_2 \
        > $OUT_BAM
    samtools index $OUT_BAM

    # ### vcfs ###
    # VCF_DIR="${PROJECT_DIR}/${sample}/vcf"
    # mkdir -p $BAM_DIR
    # OUT_vcf=${BAM_DIR}/${sample}.vcf.gz

    # cp $SOURCE_VCF $OUT_vcf
    # cp ${SOURCE_VCF}.tbi ${OUT_vcf}.tbi
done

# clean up yo
rm -f $TMP_BAM_1 $TMP_BAM_2 header.txt


############# VCF files #############

TMP_VCF="tmp.vcf"
curl -L https://raw.githubusercontent.com/samtools/bcftools/master/test/concat.2.b.vcf \
    -o $TMP_VCF

# add chr prefix
awk '{if($0 !~ /^#/) print "chr"$0; else print $0}' $TMP_VCF > tmp && mv tmp $TMP_VCF

for sample in A B; do
    VCF_DIR="${PROJECT_DIR}/${sample}/vcf"
    mkdir -p $VCF_DIR
    OUT_vcf=${VCF_DIR}/${sample}.vcf.gz

    cat $TMP_VCF | bgzip > $OUT_vcf
    tabix $OUT_vcf
done

# clean up yo
rm -f $TMP_VCF
