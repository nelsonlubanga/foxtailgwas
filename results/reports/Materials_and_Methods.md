# Materials and Methods

## Plant material and field experiments

A foxtail millet (*Setaria italica* (L.) P. Beauv.) diversity panel was evaluated in field experiments conducted in 2023 and 2024 at **[insert institution, field station, city, country, latitude, longitude, and elevation]**. Accession identifiers were standardized during data curation by extracting the numeric component of each identifier and representing it as `Fm<number>` (for example, `FM013` was standardized to `Fm13`). The source, biological status, geographic origin, and seed-increase history of the accessions should be described here when available: **[insert germplasm provenance]**.

The three analysis environments were designated **LN2023**, **LN2024**, and **HN2024**. LN2023 was the 2023 experiment and comprised a single low-nitrogen management regime. Each genotype was represented by three field plots, which were treated as three blocks/replicates in the statistical analysis. The 2024 experiment compared LN2024 and HN2024, corresponding to the former N40 and N120 labels and target nitrogen application rates of 40 and 120 **[insert units; expected to be kg N ha−1, but verify]**, respectively. Each nitrogen environment occupied a separate half of the field and contained three blocks per genotype. Because the nitrogen environments were physically separated rather than randomized together within a common treatment-by-block design, LN2024 and HN2024 were treated as two separate randomized complete-block trials. Consequently, BLUEs and genome-wide association analyses were calculated independently for the two nitrogen environments; no formal test of nitrogen treatment effects or genotype-by-nitrogen interaction was made in the present analysis.

Before publication, the following field-management information should be added from the trial records: **[plot dimensions and row spacing; sowing and harvest dates; soil classification and pre-sowing soil nitrogen; preceding crop; fertilizer formulation, timing, and application method; irrigation; weed, pest, and disease management; and relevant weather conditions]**.

## Phenotypic measurements

Eight phenotypes were analysed in each environment. In LN2023, the recorded traits were days to flowering (DtF), plant height (cm), plant density (plants m−2), thousand-seed weight (g), seed protein concentration (%), seed fat concentration (%), panicle length (cm), and pedicel length (cm). In LN2024 and HN2024, the recorded traits were DtF, plant height (cm), plant density (plants m−2), number of tillers, days to harvest, Normalized Difference Vegetation Index (NDVI), fluorescence, and seed protein concentration (%).

The measurement protocols and instruments were not encoded in the supplied phenotype workbook and must be inserted from the field and laboratory records. In particular, the manuscript should define the developmental event and reference date used for DtF and days to harvest; the plant organ and sampling number used for height, tiller, panicle, and pedicel measurements; the quadrat or row length used to calculate plants m−2; the instrument, acquisition date/time, canopy distance, and calibration used for NDVI and fluorescence; and the analytical method, instrument, moisture basis, and replication used for protein and fat measurements. These details should be added as **[trait measurement protocols and instrument manufacturers/models]**.

## Phenotype data curation

Phenotypic records were imported from the workbook `Field trail data Foxtail millet for PIs.xlsx`. The year-specific worksheets `Field23` and `Field24` were treated as authoritative. The combined worksheet was audited but was not used because several shared-trait headings in its 2024 section were displaced relative to the year-specific source sheet. Plot-level observations were retained, whereas spreadsheet columns containing pre-calculated averages and standard deviations were excluded to avoid using derived values as independent biological replicates.

Genotype identifiers and field labels were standardized programmatically. Empty cells, the symbol `*`, and the value zero in the DtF column were coded as missing because they did not represent valid flowering observations. A corresponding flowering-event indicator was therefore also missing for these observations. Non-positive plant-height values were coded as missing. A plant density of zero plants m−2 was retained as a potentially valid biological observation but was flagged during quality control. In the 2024 dataset, one missing nitrogen-treatment label represented by `*` was resolved from the treatment assigned to the matching genotype-block record. No other phenotype values were imputed.

The curated plot-level dataset was saved as `data/processed/phenotypes_plot_clean.csv`. Data-quality summaries were generated to assess missingness, replication, value ranges, and treatment/block balance. The complete cleaning procedure is implemented in `scripts/01_clean_phenotypes.R`.

## Estimation of genotype BLUEs

Genotype best linear unbiased estimates (BLUEs) were calculated separately for LN2023, LN2024, and HN2024 using ASReml-R version 4.2.0.482. A separate univariate model was fitted for each trait and environment. For an observation from genotype \(i\) in block \(j\), the model was

\[
y_{ij} = \mu + G_i + B_j + e_{ij},
\]

where \(y_{ij}\) is the plot-level phenotype, \(\mu\) is the intercept, \(G_i\) is the fixed effect of genotype, \(B_j\) is the random effect of block, and \(e_{ij}\) is the residual. Block effects were assumed to follow \(B_j \sim N(0,\sigma_B^2)\), and residuals were assumed independent with \(e_{ij} \sim N(0,\sigma_e^2)\). Genotype was fitted as a fixed effect because the objective was to estimate accession-specific adjusted means for GWAS. Predictions of the genotype fixed effects and their standard errors were obtained using `predict.asreml(..., classify = "genotype")`.

Models were fitted with a maximum of 50 iterations and were updated up to five times when required to achieve convergence. All 24 trait-by-environment models (eight traits in each of LN2023, LN2024, and HN2024) converged. The GWAS phenotype tables retain their legacy file names to preserve reproducibility. The model fitting and diagnostic exports are implemented in `scripts/02_phenotype_blues.R`.

## Broad-sense heritability

Broad-sense heritability was estimated separately for each of the 24 trait-by-environment combinations from plot-level observations using ASReml-R. For this analysis, genotype and block were fitted as random effects and the residual was modelled as independent plot-level error. Genotypic variance (\(\sigma_G^2\)), block variance, and residual variance (\(\sigma_e^2\)) were estimated by residual maximum likelihood. Entry-mean broad-sense heritability was calculated as

\[
H^2 = \frac{\sigma_G^2}{\sigma_G^2 + \sigma_e^2/r_{\mathrm{eff}}},
\]

where \(r_{\mathrm{eff}}\) was the harmonic mean number of observed plots per genotype within the relevant environment, thereby accommodating missing and unbalanced observations. Block variance was fitted to adjust for replication but was not included in the denominator for adjusted entry means. Plot-level heritability, \(\sigma_G^2/(\sigma_G^2+\sigma_e^2)\), was also exported for reference. All 24 models converged. Calculations and figures are generated by `scripts/13_heritability_phenotype_plots.R`; numerical results are stored in `results/phenotypes/broad_sense_heritability_by_environment.csv`.

## SNP data preparation and quality control

Genotypes were supplied in Variant Call Format as `data/raw/Fox_geno.vcf`. The input contained 236 samples and 907,886 variant records. Before filtering, the malformed `PL` FORMAT declaration was corrected from `Number=.` to the VCF-compliant genotype-number declaration `Number=G`. Missing sequence-contig declarations were added to the header using the contig names and maximum observed coordinates in the VCF; these maxima were used only to construct a valid header and should not be interpreted as true chromosome lengths. Sample identifiers were normalized to the same `Fm<number>` convention used for the phenotypes.

Only variants located on the nine anchored chromosomes (`SCAFFOLD_1`–`SCAFFOLD_9`) were retained; variants on additional or unplaced scaffolds were excluded. Quality control retained biallelic SNPs with minor allele frequency (MAF) at least 0.05 and SNP call-rate at least 0.90 (SNP missingness no greater than 0.10). Samples with genotype missingness greater than 0.10 were removed. Allele-frequency and site-missingness statistics were recalculated after sample removal. After filtering, 177 samples and 848,687 chromosome-anchored SNPs remained. The maximum missingness among retained individuals was 0.0986 and the maximum retained SNP missingness was 0.0960. The quality-controlled VCF was saved as `data/processed/genotypes/Fox_geno.qc.vcf.gz`. Genotypes were also exported in VCFtools 012 format, in which 0, 1, and 2 represent alternate-allele dosage and −1 represents a missing genotype, together with corresponding sample and position files. The complete workflow is recorded in `scripts/03_vcf_qc.sh`.

For computationally efficient analysis, the 012 matrix was converted to a signed 8-bit binary dosage matrix using the archived conversion utility `archive/python_legacy/scripts/012_to_int8_binary.py`. Missing calls were converted to dosage 1 when data were supplied to GAPIT, corresponding to GAPIT's `SNP.impute = "Middle"` option. Phenotyped accessions were matched to genotyped accessions by their standardized identifiers. Only accessions having both genotype data and a non-missing BLUE for the analysed trait were retained.

The final sample sizes were trait-dependent. For LN2023 they were: DtF, 125; height, 129; plants m−2, 129; thousand-seed weight, 86; protein, 70; fat, 65; panicle length, 93; and pedicel length, 93. For LN2024 they were: DtF, 80; height, 81; plants m−2, 81; number of tillers, 81; days to harvest, 80; NDVI, 81; fluorescence, 81; and protein, 57. For HN2024 they were: DtF, 80; height, 81; plants m−2, 75; number of tillers, 81; days to harvest, 80; NDVI, 81; fluorescence, 81; and protein, 67.

## Genome-wide association analysis

Genome-wide association studies were performed independently for every trait within LN2023, LN2024, and HN2024 using GAPIT version 4.1.0 in R version 4.6.1. Three association models were fitted to each of the 24 phenotype datasets: the mixed linear model (MLM), Fixed and Random Model Circulating Probability Unification (FarmCPU), and Bayesian-information and Linkage-disequilibrium Iteratively Nested Keyway (BLINK), giving 72 completed GWAS runs.

For all models, three principal components were included to account for broad-scale population structure (`PCA.total = 3`). For MLM, additive genomic relatedness was estimated using the VanRaden kinship method. Genotypes were represented as alternate-allele dosages and middle-genotype imputation was requested for missing calls. Genotype-view output was disabled to reduce memory and disk use, while phenotype and PCA diagnostic output was generated with the MLM analysis. The analysis is implemented in `scripts/05_gapit_all_traits.R`.

The MAF threshold of 0.05 was applied globally during VCF quality control across the 177 retained genotyped accessions. GAPIT was subsequently run with `SNP.MAF = 0`; consequently, variants whose MAF fell below 0.05 within a smaller trait-specific subset were still tested. Trait-specific allele frequencies were recalculated during downstream interpretation, and associations with trait-specific MAF below 0.05 were explicitly flagged. These low-frequency subset associations should be interpreted cautiously. A stricter sensitivity analysis in which MAF is reapplied within each trait subset is recommended before final biological claims.

The chromosome-only GWAS batch used a deterministic environment–trait–model-specific seed derived from a base seed of 20260908, providing reproducible random-number streams for all 72 analyses. One analysis (HN2024 DtF with FarmCPU) completed model fitting but failed during GAPIT's internal plotting stage because of non-finite plotting limits. It was rerun with the identical seed and parameters using `file.output = FALSE`; its returned primary GAPIT GWAS table was exported in the same format used for the other analyses. Thus, all 72 primary association tables were available for downstream analysis.

## Multiple-testing correction and significant associations

Significance was assessed separately within each trait-by-environment-by-model analysis using a Bonferroni family-wise error rate of 0.05. With 848,687 tested SNPs, the experiment-wise threshold was

\[
P \leq \frac{0.05}{848{,}687} = 5.89145 \times 10^{-8},
\]

equivalent to \(-\log_{10}(P) \geq 7.230\). Association rows meeting or exceeding this threshold were classified as significant. Summaries were produced from the primary GAPIT association table for each analysis to avoid counting duplicate format-specific exports. Across the completed analyses, 181 significant trait-by-environment-by-model association records representing 160 unique SNPs were identified. Of these, 105 association records (95 unique SNPs) had trait-specific MAF at least 0.05. The Bonferroni summaries are generated by `scripts/06_summarize_bonferroni.R` and stored under `results/gwas/summary`.

## Candidate-gene identification using the Yugu1 version 2 reference

Candidate genes were first identified against the chromosome-scale Yugu1 version 2 reference assembly (NCBI accession GCF_000263155.2) and NCBI *Setaria italica* Annotation Release 103. Reference FASTA, GFF, and assembly-report files were stored under `data/reference`. The maintained candidate-gene workflow is implemented in R in `scripts/07_candidate_gene_analysis.R`.

Linkage disequilibrium (LD) was calculated within the accessions used for the relevant trait from the original, non-imputed 012 genotype matrix. For LD calculation only, missing marker dosages were replaced by the marker mean. For each significant lead SNP, markers within ±1 Mb were considered, and markers having \(r^2 \geq 0.20\) with the lead SNP were retained. A lead-connected LD cluster was constructed from the linked markers, permitting gaps of no more than 20 kb between successive linked markers. Candidate intervals were capped at ±250 kb around the lead SNP to limit exceptionally long intervals. All annotated genes overlapping the resulting interval were reported; where no gene overlapped the interval, the nearest annotated gene was reported. Associations whose trait-specific MAF was below 0.05 were retained in the comprehensive output but flagged.

This procedure yielded 1,053 association–gene links representing 735 unique version 2 genes. A conservative subset was defined as genes directly containing the lead SNP for associations with trait-specific MAF at least 0.05; this subset contained 12 association–gene links and 11 unique genes.

## Independent candidate-gene analysis using the telomere-to-telomere reference

Candidate genes were also identified independently using the Yugu1 telomere-to-telomere assembly (Yugu1 T2T v1.0) described by He et al. (2024). The genome sequence, GFF3 annotation, functional annotation table, identifier-conversion table, and distributed checksum files were obtained from Setaria-db and saved under `data/reference/Yugu1_T2T_v1.0`; downloaded files were verified against the supplied checksums.

Because the GWAS marker coordinates originated from the older reference, the NCBI Yugu1 version 2 assembly was aligned as query to the Yugu1 T2T assembly as target using minimap2 version 2.31 with the assembly-to-assembly preset, CIGAR output, and secondary alignments disabled (`-x asm5 --secondary=no -c`). Coordinate conversion was CIGAR-aware and required a uniquely accepted mapping. Of the 181 significant association records, 180 were uniquely lifted to the T2T reference and one could not be mapped; no ambiguous conversion was accepted.

For each successfully lifted association, markers defining its version 2 LD interval were independently converted to the T2T assembly. The minimum and maximum uniquely lifted coordinates on the same T2T chromosome defined the corresponding T2T candidate interval. T2T genes overlapping this interval were reported; the nearest gene was used where no annotation overlapped the interval. Setaria-db functional descriptions were integrated using the T2T functional-annotation and identifier-conversion tables. This analysis generated 1,602 association–gene links representing 1,047 unique T2T genes. In the conservative subset requiring a lead SNP to fall within a gene and trait-specific MAF to be at least 0.05, 24 distinct associations produced 25 links to 22 unique T2T genes. The maintained workflow is implemented in R in `scripts/08_t2t_candidate_gene_analysis.R`, with outputs under `results/gwas/candidate_genes_r/reference_comparison`.

The version 2 and T2T analyses were retained as complementary results rather than merging gene identifiers uncritically. Agreement between the assemblies provides stronger positional support, whereas assembly-specific assignments may reflect corrected sequence, coordinate, gap, or annotation structure in the T2T reference. Functional relevance, expression evidence, and local haplotype structure should be considered before nominating a gene as causal.

## Graphical presentation and reproducibility

GAPIT-generated Manhattan and quantile–quantile plots were retained as analysis diagnostics. Final Manhattan and quantile–quantile plots were regenerated from the saved association tables in R using `data.table`, `ggplot2`, `patchwork`, and `scales`. Variants with trait-subset MAF below 0.05 were omitted from the final figures, while the conservative Bonferroni threshold based on all 848,687 chromosome-anchored, globally quality-controlled SNPs was displayed. Manhattan plots used human-readable trait names, alternating chromosome colours, chromosomes 1–9 in physical order, and large red, black-outlined points to identify Bonferroni-significant SNPs. Quantile–quantile plots included the identity line and the genomic inflation factor λ.

Genotype-effect plots were produced in R for the 12 distinct dataset–trait–lead-SNP combinations in which a significant lead SNP with trait-specific MAF at least 0.05 occurred within an annotated Yugu1 version 2 gene. Plots show the BLUE distribution by alternate-allele dosage, genotype-class sample sizes, boxplots, enlarged individual observations, and class means. Random horizontal jitter used a fixed random-number-generator seed of 20260907. Regional association plots were produced in R for the seven recurrent loci with trait-specific MAF at least 0.05. Each plot used a ±250-kb window, displayed enlarged markers coloured by LD (r²) with the lead SNP, identified the lead SNP, showed the Bonferroni threshold, and included genes from the corresponding candidate interval. All final figure types are generated by `scripts/09_publication_figures.R` and saved under `figures/publication_r_final`.

All major processing stages are scripted and their outputs are stored within the project under `data/processed`, `results/gwas`, and `figures`. No spreadsheet-derived averages were used as replicates, phenotype imputation was not performed, and the two 2024 nitrogen regimes were analysed independently. The maintained candidate-gene and figure workflows used R version 4.6.1, data.table version 1.18.4, ggplot2 version 4.0.3, patchwork version 1.3.2, and scales version 1.4.0. Whole-genome assembly alignment used minimap2 version 2.31.

## Information required before manuscript submission

The following details were not recoverable from the supplied analytical files and should be completed by the authors:

1. Trial location, coordinates, elevation, soil properties, and weather summary.
2. Germplasm source and accession-selection criteria.
3. Plot dimensions, planting density, experimental randomization procedure, sowing dates, and harvest dates.
4. Confirmation that LN2024 and HN2024 correspond to 40 and 120 kg N ha−1, respectively, plus fertilizer source, timing, and application method.
5. Exact field and laboratory protocols, sampling units, instruments, manufacturers, and models for every phenotype.
6. Genotyping platform, library construction, read processing, alignment, variant calling, and original reference assembly used to generate `Fox_geno.vcf`.
7. Whether the GWAS will be rerun with an explicit seed and trait-specific MAF filtering for the final reported analysis.
8. Repository or archive accession through which scripts, processed phenotypes, genotype data permitted for release, and association summary statistics will be made available.

## References cited in the methods

- Bennetzen JL, Schmutz J, Wang H, et al. (2012). Reference genome sequence of the model plant *Setaria*. *Nature Biotechnology* 30:555–561. https://doi.org/10.1038/nbt.2196
- He Q, et al. (2024). A complete reference genome assembly for foxtail millet and Setaria-db, a comprehensive database for *Setaria*. *Molecular Plant* 17:219–222. https://doi.org/10.1016/j.molp.2023.12.017
- Huang M, Liu X, Zhou Y, Summers RM, Zhang Z (2019). BLINK: a package for the next level of genome-wide association studies with both individuals and markers in the millions. *GigaScience* 8:giy154. https://doi.org/10.1093/gigascience/giy154
- Li H (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics* 34:3094–3100. https://doi.org/10.1093/bioinformatics/bty191
- Lipka AE, Tian F, Wang Q, et al. (2012). GAPIT: genome association and prediction integrated tool. *Bioinformatics* 28:2397–2399. https://doi.org/10.1093/bioinformatics/bts444
- Liu X, Huang M, Fan B, Buckler ES, Zhang Z (2016). Iterative usage of fixed and random effect models for powerful and efficient genome-wide association studies. *PLoS Genetics* 12:e1005767. https://doi.org/10.1371/journal.pgen.1005767
- VanRaden PM (2008). Efficient methods to compute genomic predictions. *Journal of Dairy Science* 91:4414–4423. https://doi.org/10.3168/jds.2007-0980

---

**Draft status:** This document describes the analysis that was actually performed and deliberately flags missing experimental metadata and analytical limitations. Text in bold square brackets must be completed from the field, laboratory, and genotyping records before journal submission.
