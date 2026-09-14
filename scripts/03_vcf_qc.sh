#!/usr/bin/env bash
set -euo pipefail

raw_vcf="data/raw/Fox_geno.vcf"
out_dir="data/processed/genotypes"
tmp_dir="${TMPDIR:-/tmp}/foxtail_vcf_qc"
anchored_chromosomes="SCAFFOLD_1,SCAFFOLD_2,SCAFFOLD_3,SCAFFOLD_4,SCAFFOLD_5,SCAFFOLD_6,SCAFFOLD_7,SCAFFOLD_8,SCAFFOLD_9"

mkdir -p "$out_dir" "$tmp_dir"

# Build a sequence dictionary using the maximum observed position per scaffold.
awk 'BEGIN{FS="\t"} !/^#/ {if ($2>max[$1]) max[$1]=$2} END {for (c in max) print c"\t"max[c]}' \
  "$raw_vcf" | sort -V > "$out_dir/Fox_geno.contigs.fai"

# Normalize sample names (FM228/Fm013 -> Fm228/Fm13). The normalized names are
# unique in this dataset.
bcftools query -l "$raw_vcf" | \
  awk '{x=$0; gsub(/[^0-9]/,"",x); print "Fm" (x+0)}' \
  > "$out_dir/Fox_geno.normalized_samples.txt"

# Rebuild the malformed header before asking bcftools to parse variant records.
# PL is a genotype-level vector and therefore has Number=G. Add a sequence
# dictionary derived above, then normalize sample names during reheadering.
bcftools view -h "$raw_vcf" > "$tmp_dir/original_header.txt"
awk 'BEGIN{FS=OFS="\t"} \
  NR==FNR {contig[++n]=$1; len[$1]=$2; next} \
  /^##FORMAT=<ID=PL,/ {sub(/Number=\./,"Number=G")} \
  /^#CHROM/ {for(i=1;i<=n;i++) print "##contig=<ID="contig[i]",length="len[contig[i]]">"} \
  {print}' "$out_dir/Fox_geno.contigs.fai" "$tmp_dir/original_header.txt" \
  > "$tmp_dir/corrected_header.txt"
bcftools reheader --threads 4 \
  -h "$tmp_dir/corrected_header.txt" \
  -s "$out_dir/Fox_geno.normalized_samples.txt" \
  -o "$tmp_dir/header_fixed.vcf" "$raw_vcf"
bcftools view --threads 4 -Oz \
  -o "$out_dir/Fox_geno.corrected.vcf.gz" "$tmp_dir/header_fixed.vcf"
bcftools index --threads 4 -t -f "$out_dir/Fox_geno.corrected.vcf.gz"

# Sample QC: retain individuals with at most 10% missing genotype calls.
bcftools +smpl-stats "$out_dir/Fox_geno.corrected.vcf.gz" \
  -o "$out_dir/sample_stats_before_qc.tsv"
awk 'BEGIN{FS=OFS="\t"} /^FLT/ {rate=$12/($3+$12); if(rate<=0.10) print $2}' \
  "$out_dir/sample_stats_before_qc.tsv" > "$out_dir/samples_kept.txt"
awk 'BEGIN{FS=OFS="\t"; print "sample","called","missing","missing_rate","status"} \
  /^FLT/ {rate=$12/($3+$12); print $2,$3,$12,rate,(rate<=0.10?"kept":"removed")}' \
  "$out_dir/sample_stats_before_qc.tsv" > "$out_dir/sample_missingness_qc.tsv"

# Site QC after sample removal: retain biallelic SNPs with MAF >= 0.05 and no
# more than 10% missing calls. AF/MAF are recalculated in retained samples.
bcftools view --threads 4 -r "$anchored_chromosomes" -S "$out_dir/samples_kept.txt" -Ou \
  "$out_dir/Fox_geno.corrected.vcf.gz" | \
  bcftools +fill-tags -Ou -- -t AC,AN,AF,MAF | \
  bcftools view --threads 4 -m2 -M2 -v snps \
    -i 'MAF>=0.05 && F_MISSING<=0.10' -Oz \
    -o "$out_dir/Fox_geno.qc.vcf.gz"
bcftools index --threads 4 -t -f "$out_dir/Fox_geno.qc.vcf.gz"

bcftools stats "$out_dir/Fox_geno.corrected.vcf.gz" \
  > "$out_dir/vcf_stats_before_qc.txt"
bcftools stats "$out_dir/Fox_geno.qc.vcf.gz" \
  > "$out_dir/vcf_stats_after_qc.txt"

python3 archive/python_legacy/scripts/vcf_to_012.py \
  "$out_dir/Fox_geno.qc.vcf.gz" "$out_dir/Fox_geno.qc"
python3 archive/python_legacy/scripts/012_to_int8_binary.py \
  "$out_dir/Fox_geno.qc.012" "$out_dir/Fox_geno.qc.int8.bin"

echo "QC completed. Outputs are in $out_dir"
