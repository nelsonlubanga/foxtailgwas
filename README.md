# Foxtail millet GWAS

Reproducible R workflow for phenotype curation, ASReml-R BLUE estimation,
three-model genome-wide association analysis, candidate-gene identification
against two Yugu1 reference assemblies, and publication figures for the
Nottingham foxtail millet field trials.

Run all commands from the project root:

```sh
cd /Users/nel6/Desktop/Documents/Collaborations/nottingham/foxtailgwas
```

## Analysis design

- The 2023 low-nitrogen trial is designated LN2023 and analysed as one environment with three blocks.
- The 2024 LN2024 (formerly N40) and HN2024 (formerly N120) trials are analysed separately because they occupied
  different field halves.
- Eight traits are analysed per environment, giving 24 phenotype datasets.
- MLM, FarmCPU, and BLINK are run for every dataset, giving 72 GWAS analyses.
- Significance uses Bonferroni correction at family-wise `alpha = 0.05`.
- Candidate genes are identified independently with Yugu1 version 2 and Yugu1
  T2T version 1.0.

## Project structure

```text
data/
  raw/                              Original phenotype workbook and VCF
  processed/
    phenotypes_plot_clean.csv       Curated plot-level phenotypes
    blues/                          BLUE tables and model diagnostics
    genotypes/                      Quality-controlled genotype data
    qc/                             Phenotype audit and QC tables
    reference_alignment/            Yugu1 v2-to-T2T alignment
  reference/                        Yugu1 v2 and T2T reference files
scripts/                            Active R analysis scripts
results/gwas/
  summary/                          Bonferroni summaries
  candidate_genes_r/                R candidate-gene results
figures/
  qc/                               Phenotype diagnostic figures
  publication_r_final/              Final R publication figures
archive/                            Legacy material; not an active workflow
```

## Software requirements

The validated workflow used R 4.6.1 with:

- `readxl`, `dplyr`, `readr`, `stringr`, and `tidyr`
- `asreml` 4.2.0.482 (a valid ASReml-R licence is required)
- `GAPIT` 4.1.0
- `data.table` 1.18.4
- `ggplot2` 4.0.3
- `patchwork` 1.3.2
- `scales` 1.4.0

The T2T R analysis reads the precomputed whole-genome alignment at
`data/processed/reference_alignment/Yugu1_v2_to_T2T.paf`, produced with
minimap2 2.31.

## Required inputs

- `data/raw/Field trail data Foxtail millet for PIs.xlsx`
- `data/processed/genotypes/Fox_geno.qc.012`
- `data/processed/genotypes/Fox_geno.qc.012.indv`
- `data/processed/genotypes/Fox_geno.qc.012.pos`
- `data/processed/genotypes/Fox_geno.qc.int8.bin`
- Yugu1 version 2 reference FASTA, GFF, and assembly report in
  `data/reference/`
- Yugu1 T2T genome, GFF3, and functional annotation files in
  `data/reference/Yugu1_T2T_v1.0/`
- `data/processed/reference_alignment/Yugu1_v2_to_T2T.paf`

The active genotype dataset contains 177 individuals and 848,687 SNPs after
retaining only chromosomes 1–9 and applying the following filters: biallelic
SNPs, MAF at least 0.05, SNP missingness at most 0.10, and individual
missingness at most 0.10. Additional and unplaced scaffolds are excluded.

## R workflow

### 1. Curate phenotypes

```sh
Rscript scripts/01_clean_phenotypes.R
```

The year-specific `Field23` and `Field24` worksheets are authoritative. The
combined worksheet is excluded because its 2024 shared-trait headings are
shifted. Spreadsheet averages and standard deviations are not used as
replicates. For days to flowering, `0`, `*`, and blank values are missing.
Non-positive height values are missing; zero plants m−2 is retained and flagged.
No phenotype values are imputed.

Principal output: `data/processed/phenotypes_plot_clean.csv`.

### 2. Estimate BLUEs with ASReml-R

```sh
Rscript scripts/02_phenotype_blues.R
```

Each trait is fitted separately as:

```text
trait ~ genotype
random = ~ block
residual = ~ idv(units)
```

Genotype is fixed and block is random. LN2024 and HN2024 are fitted independently.
All 24 models in the validated run converged. Primary GWAS phenotype files are:

- `data/processed/blues/gwas_phenotypes_2023.csv`
- `data/processed/blues/gwas_phenotypes_2024_N40.csv`
- `data/processed/blues/gwas_phenotypes_2024_N120.csv`

### 2b. Estimate broad-sense heritability and plot phenotypes

```sh
Rscript scripts/13_heritability_phenotype_plots.R
```

Genotype and block are fitted as random effects separately within LN2023, LN2024,
and HN2024. Entry-mean broad-sense heritability uses the harmonic-mean effective
replication to account for missing or unbalanced plot records. Numerical results
are written to `results/phenotypes/`, and heritability bar plots and phenotype
box plots are written to `figures/publication_r_final/phenotypes/`.

### 3. Run all GWAS models

```sh
Rscript scripts/05_gapit_all_traits.R
```

GAPIT fits MLM, FarmCPU, and BLINK using three principal components. MLM uses
VanRaden kinship. Results are written to:

```text
results/gwas/<environment>/<trait>/<model>/
```

The completed historical batch did not set an explicit random seed. The saved
tables are the definitive output of that run. Add a fixed seed and rerun all
models if exact FarmCPU/BLINK rerun reproducibility is required.

The pilot in `scripts/04_gapit_pilot_2023_height.R` is optional and is not part
of the complete run.

### 4. Summarize Bonferroni-significant associations

```sh
Rscript scripts/06_summarize_bonferroni.R
```

With 848,687 tested markers, the threshold is
`0.05 / 848687 = 5.89145e-08`. Outputs are saved in `results/gwas/summary/`.
The current run contains 181 significant association records representing
160 unique SNPs; 105 records representing 95 unique SNPs have trait-specific
MAF at least 0.05.

MAF 0.05 was applied globally to the 177 genotyped accessions. GAPIT subsequently
used `SNP.MAF = 0`, so MAF can fall below 0.05 in smaller trait subsets.
Candidate tables retain and flag these records using
`trait_specific_maf_pass`. Final figures display variants with trait-subset MAF
at least 0.05 and retain the original conservative Bonferroni line.

### 5. Identify Yugu1 version 2 candidate genes

```sh
Rscript scripts/07_candidate_gene_analysis.R
```

LD is calculated within the individuals used for each trait. Missing genotypes
are marker-mean imputed for LD calculation only. Candidate intervals use:

- a ±1-Mb LD search window;
- `r² >= 0.20` with the lead SNP;
- a lead-connected cluster with linked-marker gaps no greater than 20 kb; and
- a maximum interval radius of ±250 kb.

Genes overlapping an interval are returned; otherwise, the nearest gene is
reported. Results are saved in `results/gwas/candidate_genes_r/`. The validated
analysis contains 1,053 association–gene links and 735 unique genes.

### 6. Identify Yugu1 T2T candidate genes

```sh
Rscript scripts/08_t2t_candidate_gene_analysis.R
```

The script performs CIGAR-aware conversion from Yugu1 version 2 to Yugu1 T2T
using the stored alignment. Only uniquely accepted interval-marker mappings on
the lead SNP's T2T chromosome define each T2T interval. Setaria-db functional
annotations are added.

Results are written to
`results/gwas/candidate_genes_r/reference_comparison/`. Of 181 associations,
180 mapped uniquely and one was unmapped. The analysis contains 1,602
association–gene links and 1,047 unique genes.

### 7. Generate publication figures

```sh
Rscript scripts/09_publication_figures.R
```

The script uses `set.seed(20260907)` and produces:

- 72 Manhattan plots as 300-dpi PNG files;
- 72 QQ plots as 300-dpi PNG files, including genomic inflation factor λ;
- 12 lead-SNP genotype-effect plots as PDF and 300-dpi PNG; and
- seven LD-coloured regional plots as PDF and 300-dpi PNG.

Final figures are saved in `figures/publication_r_final/`.
`gwas_figure_manifest.csv` records the input table, marker counts, trait-subset
MAF display filter, Bonferroni threshold, and λ for each GWAS figure.

### 8. Build the PowerPoint presentation

```sh
Rscript scripts/10_create_presentation.R
```

This script uses the supplied GAAFS–Roslin PowerPoint template and the validated
summary tables and R figures to produce a 13-slide presentation, including a
complete slide for every trait in LN2023, LN2024, and HN2024. The output is saved as
`results/reports/Foxtail_Millet_GWAS_Presentation_NO_LOGOS_2026-09-10.pptx`.

## Complete execution order

```sh
Rscript scripts/01_clean_phenotypes.R
Rscript scripts/02_phenotype_blues.R
Rscript scripts/05_gapit_all_traits.R
Rscript scripts/06_summarize_bonferroni.R
Rscript scripts/07_candidate_gene_analysis.R
Rscript scripts/08_t2t_candidate_gene_analysis.R
Rscript scripts/09_publication_figures.R
Rscript scripts/10_create_presentation.R
```

The GWAS stage is computationally intensive. Check
`results/gwas/batch_status.csv` before rerunning it.

## Validated and reportable outputs

The active outputs correspond exclusively to the chromosome-only analysis with
10% individual and SNP missingness thresholds. Earlier parameterizations are
retained under `archive/` and must not be used for current reporting.

Use these outputs for continued analysis and reporting:

- `results/gwas/summary/`
- `results/gwas/candidate_genes_r/`
- `figures/publication_r_final/`
- `results/reports/Materials_and_Methods.docx`
- `results/reports/Foxtail_Millet_GWAS_Presentation_NO_LOGOS_2026-09-10.pptx`

Only the R workflow documented above should be used for continued analysis and
figure regeneration.
