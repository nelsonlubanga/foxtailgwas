# Foxtail millet GWAS: fresh presentation summary

## Headline

Using 177 accessions and 848,687 chromosome-anchored SNPs after 10% individual and SNP missingness filtering, 181 Bonferroni-significant association records representing 160 unique SNPs were detected. The preferred trait-specific MAF ≥0.05 subset contained 105 records representing 95 unique SNPs.

## Study and QC

- Environments: 2023, 2024 N40 and 2024 N120.
- N40 and N120 were analysed independently, not as a randomized treatment contrast.
- Eight traits per environment and three GWAS models produced 72 analyses.
- Genotype filters: chromosomes 1–9 only, biallelic SNPs, global MAF ≥0.05, individual missingness ≤0.10, and SNP missingness ≤0.10.
- Final genotype dataset: 177 individuals and 848,687 SNPs.
- Trait-specific GWAS sample sizes: 57–129.
- Bonferroni threshold: \(P \leq 5.89145\times10^{-8}\), or \(-\log_{10}(P)\geq7.230\).
- A deterministic model-specific seed derived from 20260908 was used.

## Overall results

| Category | Count |
|---|---:|
| Significant association records | 181 |
| Unique significant SNPs | 160 |
| Trait-MAF-supported records | 105 |
| Trait-MAF-supported unique SNPs | 95 |
| Recurrent MAF-supported SNPs | 7 |

Association records count a SNP again when it occurs in another model, trait or environment. Emphasize the 95 MAF-supported unique SNPs and recurrent loci rather than treating all 181 records as independent discoveries.

## Results by environment

| Environment | Records | Unique SNPs | MAF-supported records | MAF-supported SNPs |
|---|---:|---:|---:|---:|
| 2023 | 46 | 45 | 34 | 33 |
| N40 | 64 | 58 | 36 | 32 |
| N120 | 71 | 61 | 35 | 32 |

N120 had the largest total record count, but N40 and N120 each retained 32 unique SNPs after the trait-specific MAF screen. Raw hit counts are influenced by sample size, allele frequency, phenotype distribution and model behaviour.

## Complete per-trait summary: 2023

| Trait | n | Records | Unique SNPs | MAF-supported records | MAF-supported SNPs | Strongest supported SNP |
|---|---:|---:|---:|---:|---:|---|
| Days to flowering | 125 | 14 | 13 | 13 | 12 | S7:17,136,277; P=2.66×10−23 |
| Plant height | 129 | 1 | 1 | 1 | 1 | S1:38,761,213; P=2.97×10−12 |
| Plant density | 129 | 0 | 0 | 0 | 0 | None |
| Thousand-seed weight | 86 | 3 | 3 | 2 | 2 | S1:33,452,294; P=4.63×10−11 |
| Seed protein | 70 | 0 | 0 | 0 | 0 | None |
| Seed fat | 65 | 0 | 0 | 0 | 0 | None |
| Panicle length | 93 | 11 | 11 | 11 | 11 | S3:47,440,311; P=3.90×10−15 |
| Pedicel length | 93 | 17 | 17 | 7 | 7 | S8:10,301,084; P=9.14×10−12 |

## Complete per-trait summary: N40

| Trait | n | Records | Unique SNPs | MAF-supported records | MAF-supported SNPs | Strongest supported SNP |
|---|---:|---:|---:|---:|---:|---|
| Days to flowering | 80 | 17 | 14 | 13 | 11 | S2:30,514,256; P=7.22×10−20 |
| Plant height | 81 | 7 | 7 | 5 | 5 | S9:9,021,917; P=8.97×10−22 |
| Plant density | 81 | 0 | 0 | 0 | 0 | None |
| Number of tillers | 81 | 28 | 27 | 8 | 8 | S6:32,361,467; P=5.35×10−19 |
| Days to harvest | 80 | 7 | 7 | 7 | 7 | S7:2,121,353; P=1.07×10−31 |
| NDVI | 81 | 0 | 0 | 0 | 0 | None |
| Fluorescence | 81 | 0 | 0 | 0 | 0 | None |
| Seed protein | 57 | 5 | 4 | 3 | 2 | S4:15,902,894; P=5.38×10−16 |

## Complete per-trait summary: N120

| Trait | n | Records | Unique SNPs | MAF-supported records | MAF-supported SNPs | Strongest supported SNP |
|---|---:|---:|---:|---:|---:|---|
| Days to flowering | 80 | 11 | 9 | 10 | 8 | S8:3,818,991; P=1.02×10−20 |
| Plant height | 81 | 10 | 9 | 9 | 8 | S9:9,021,917; P=5.08×10−14 |
| Plant density | 75 | 0 | 0 | 0 | 0 | None |
| Number of tillers | 81 | 32 | 28 | 4 | 4 | S4:22,532,145; P=6.33×10−10 |
| Days to harvest | 80 | 7 | 6 | 4 | 4 | S8:30,155,739; P=1.16×10−12 |
| NDVI | 81 | 0 | 0 | 0 | 0 | None |
| Fluorescence | 81 | 0 | 0 | 0 | 0 | None |
| Seed protein | 67 | 11 | 10 | 8 | 8 | S6:28,801,701; P=5.58×10−18 |

Plant density, NDVI and fluorescence produced no significant associations under the final QC. Seed fat and 2023 seed protein also produced no significant associations.

## Model contributions

| Model | Records | Unique SNPs | MAF-supported records | MAF-supported SNPs | Median λGC |
|---|---:|---:|---:|---:|---:|
| FarmCPU | 89 | 84 | 66 | 64 | 0.959 |
| BLINK | 53 | 50 | 38 | 36 | 0.998 |
| MLM | 39 | 39 | 1 | 1 | 0.992 |

FarmCPU detected the largest number of supported signals. Median inflation factors were close to one, but individual QQ plots should still be inspected; the maximum λ was 1.228 for BLINK.

## Strongest MAF-supported signals

| Environment/trait | Model | SNP | P-value | MAF | Effect |
|---|---|---|---:|---:|---:|
| N40 days to harvest | FarmCPU | S7:2,121,353 | 1.07×10−31 | 0.069 | +24.99 |
| 2023 flowering | FarmCPU | S7:17,136,277 | 2.66×10−23 | 0.120 | +10.88 |
| N40 height | FarmCPU | S9:9,021,917 | 8.97×10−22 | 0.093 | +13.30 |
| N120 flowering | BLINK | S8:3,818,991 | 1.02×10−20 | 0.113 | +20.96 |
| N40 flowering | BLINK | S2:30,514,256 | 7.22×10−20 | 0.163 | +11.52 |
| N40 tillers | FarmCPU | S6:32,361,467 | 5.35×10−19 | 0.099 | +1.48 |
| N120 protein | FarmCPU | S6:28,801,701 | 5.58×10−18 | 0.104 | +3.17 |

Effects use alternate-allele dosage and the units of the corresponding BLUE.

## Recurrent MAF-supported loci

- S8:3,818,991 — flowering; four records across N40 and N120; BLINK/FarmCPU.
- S2:30,514,256 — N40 flowering and days to harvest; three records; BLINK/FarmCPU.
- S7:17,136,277 — 2023 flowering; BLINK/FarmCPU.
- S9:9,021,917 — plant height in N40 and N120; FarmCPU.
- S4:15,902,894 — N40 seed protein; BLINK/FarmCPU.
- S8:7,342,725 — N120 flowering; BLINK/FarmCPU.
- S8:33,914,787 — N120 height; BLINK/FarmCPU.

The shared height locus S9:9,021,917 and shared flowering locus S8:3,818,991 are especially useful for follow-up across nitrogen environments.

## Candidate-gene analysis

| Reference | Association–gene links | Unique genes | Direct-overlap MAF-supported subset |
|---|---:|---:|---:|
| Yugu1 v2 | 1,053 | 735 | 12 links; 11 genes |
| Yugu1 T2T | 1,602 | 1,047 | 25 links; 24 associations; 22 genes |

Of 181 associations, 180 lifted uniquely to T2T and one was unmapped. Reference choice changed interval composition and direct gene assignments; T2T counts are annotations of the same association evidence, not additional GWAS discoveries.

Direct-overlap candidates include:

- SULTR3;4, a probable sulfate transporter, for N40 tiller number.
- PLP3, a patatin-like protein, for N40 tiller number.
- APT1 and RSL2/bHLH139-like genes within the 2023 panicle-length region.
- dnaJ1/uncharacterized LOC101765238 for N120 days to harvest.
- THYN1/Seita.9G141300 at the height locus shared by N40 and N120; functional relevance is presently unclear.

These are positional hypotheses. None should be described as causal without replication, expression evidence and functional validation.

## Conclusions

1. The final analysis identified 95 unique Bonferroni-significant SNPs with trait-specific MAF ≥0.05.
2. Flowering time, height, tiller number, days to harvest, panicle/pedicel length and protein produced supported signals.
3. Seven recurrent loci provide the strongest priorities for validation.
4. S8:3,818,991 for flowering and S9:9,021,917 for height were detected across N40 and N120.
5. The strongest signal was S7:2,121,353 for days to harvest under N40.
6. Candidate-gene results are reference dependent and require functional evidence.

## Limitations and next steps

- Reapply MAF ≥0.05 inside each trait subset and rerun as a sensitivity analysis.
- Validate priority SNPs in an independent population or season.
- Examine local haplotypes and LD around recurrent loci.
- Generate tissue- and stage-matched expression data under N40 and N120.
- Do not claim formal nitrogen treatment effects or genotype-by-nitrogen interaction from the present layout.
- Do not carry forward LOGL7 or other candidates from the archived 20%-missingness analysis; they are not current results.

## Thirty-second summary

“After restricting the dataset to chromosomes one to nine and applying 10% missingness thresholds, we retained 177 accessions and 848,687 SNPs. Across 72 seeded GWAS analyses, we detected 181 Bonferroni-significant records representing 160 unique SNPs. The preferred trait-specific MAF subset contained 95 unique SNPs, including seven recurrent loci. Flowering and height loci were shared across the separately analysed N40 and N120 environments, while the strongest association was for days to harvest under N40. Candidate-gene analysis with both Yugu1 version 2 and T2T references produced a focused set of direct-overlap genes, but these remain positional hypotheses requiring independent validation.”
