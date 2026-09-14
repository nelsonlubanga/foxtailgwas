#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(officer);library(flextable);library(data.table)})
root<-normalizePath("."); template<-"/Users/nel6/Desktop/Documents/Collaborations/University of Cape Town/QC.pptx"
output<-file.path(root,"results/reports/Foxtail_Millet_GWAS_Presentation_NO_LOGOS_2026-09-10.pptx"); fig<-file.path(root,"figures/publication_r_final")
master<-"GAAFS-Roslin Teaching Template 2026 v1"; navy<-"#18354A"; blue<-"#2B6F9F"; pale<-"#EAF2F7"; red<-"#B2182B"; grey<-"#4D4D4D"; white<-"#FFFFFF"
ppt<-read_pptx(template); while(length(ppt)>0)ppt<-remove_slide(ppt,index=length(ppt))
relabel_env<-function(x){
  x<-gsub("2024 N120","HN2024",x,fixed=TRUE); x<-gsub("2024 N40","LN2024",x,fixed=TRUE)
  x<-gsub("N120","HN2024",x,fixed=TRUE); x<-gsub("N40","LN2024",x,fixed=TRUE)
  gsub("(?<!LN)2023","LN2023",x,perl=TRUE)
}
add_base<-function(title){
  ppt<<-add_slide(ppt,layout="Blank Slide With Title (no logos)",master=master)
  ppt<<-ph_with(ppt,relabel_env(title),location=ph_location_label("Title"))
}
textbox<-function(text,left,top,width,height,size=20,color=grey,bold=FALSE,align="left",bg=NULL){
  value<-fpar(ftext(relabel_env(text),fp_text(font.family="Arial",font.size=size,color=color,bold=bold)),fp_p=fp_par(text.align=align));loc<-ph_location(left=left,top=top,width=width,height=height)
  if(is.null(bg))ph_with(ppt,value,location=loc)else ph_with(ppt,value,location=loc,bg=bg)}
bullets<-function(items,top=1.5,size=19){pars<-lapply(relabel_env(items),function(z)fpar(ftext(paste0("•  ",z),fp_text(font.family="Arial",font.size=size,color=grey)),fp_p=fp_par(padding.bottom=8)));ph_with(ppt,do.call(block_list,pars),location=ph_location(left=.75,top=top,width=11.8,height=4.8))}
callout<-function(value,label,left,top,width=2.8){ppt<<-textbox(value,left,top,width,.72,30,white,TRUE,"center",blue);ppt<<-textbox(label,left,top+.78,width,.65,13,navy,TRUE,"center",pale)}
add_image<-function(path,left,top,width,height){stopifnot(file.exists(path));ph_with(ppt,external_img(path,width=width,height=height),location=ph_location(left=left,top=top,width=width,height=height))}
add_table<-function(dat,left=.65,top=1.45,width=12,height=4.95,font=12,widths=NULL){ft<-flextable(dat);ft<-theme_vanilla(ft);ft<-bg(ft,part="header",bg=navy);ft<-color(ft,part="header",color=white);ft<-bold(ft,part="header");ft<-font(ft,fontname="Arial",part="all");ft<-fontsize(ft,size=font,part="all");ft<-align(ft,align="center",part="all");ft<-valign(ft,valign="center",part="all");ft<-padding(ft,padding=3,part="all");ft<-bg(ft,i=seq(2,nrow(dat),2),bg="#F3F6F8",part="body");if(is.null(widths))ft<-autofit(ft)else for(j in seq_along(widths))ft<-width(ft,j=j,width=widths[j]);ph_with(ppt,ft,location=ph_location(left=left,top=top,width=width,height=height))}
add_notes<-function(text){ppt<<-set_notes(ppt,value=relabel_env(text),location=notes_location_type("body"))}
add_table_raw<-add_table
add_table<-function(dat,...){dat[]<-lapply(dat,function(x)if(is.character(x))relabel_env(x)else x);add_table_raw(dat,...)}

# 1 Title: constructed on the official no-logo layout.
ppt<-add_slide(ppt,layout="Blank Slide With Title (no logos)",master=master)
ppt<-ph_with(ppt,"Genetic architecture of agronomic and physiological traits in foxtail millet",location=ph_location_label("Title"))
ppt<-textbox("Separate GWAS in LN2023, LN2024 and HN2024 field environments",1.0,2.15,11.3,.75,24,navy,FALSE,"center")
ppt<-textbox("Dr. Nelson Lubanga\nInstitute of Biological, Environmental and Rural Sciences\nAberystwyth University",1.4,3.45,10.5,1.5,18,grey,FALSE,"center")
add_notes(c("Good morning/afternoon. Today I will present our genome-wide association analysis of agronomic and physiological traits in foxtail millet.","The key feature of the study is that LN2023, LN2024 and HN2024 were analysed separately. This allows us to identify both environment-specific and repeatable genetic signals.","I will first outline the design and quality control, then summarize the GWAS results, highlight recurrent loci and conclude with candidate genes and priorities for validation."))

# 2 Design
add_base("Study design and analysis workflow")
ppt<-bullets(c("LN2023, LN2024 and HN2024 analysed separately","Eight traits per environment → 24 phenotype datasets","ASReml-R BLUEs: genotype fixed; block random","MLM, FarmCPU and BLINK → 72 seeded GWAS analyses","177 accessions and 848,687 chromosome-anchored SNPs","10% individual and SNP missingness; MAF ≥ 0.05; chromosomes 1–9 only"))
ppt<-textbox("The design supports environment-specific GWAS, not a formal genotype-by-nitrogen interaction test.",.9,6.05,11.5,.48,15,red,TRUE,"center")
add_notes(c("We treated LN2023, LN2024 and HN2024 as three separate environments. Eight traits were analysed in each, giving 24 phenotype datasets.","Genotype BLUEs were estimated in ASReml-R with genotype fitted as a fixed effect and block fitted as a random effect.","Each phenotype was then analysed with MLM, FarmCPU and BLINK, producing 72 GWAS analyses. Deterministic seeds were used for reproducibility.","After quality control, 177 accessions and 848,687 biallelic SNPs remained. Only chromosomes 1 to 9 were retained; unplaced scaffolds were removed. Both sample and SNP missingness thresholds were 10 percent, and the marker-level MAF threshold was 0.05.","A limitation to keep in mind is that separate LN2024 and HN2024 GWAS identify nitrogen-environment-specific signals, but do not formally test genotype-by-nitrogen interaction."))

# 3 Headline results
add_base("Genome-wide association results: headline numbers")
headline<-data.frame(
  Result=c("Significant association records","Unique significant SNPs","Prioritized unique SNPs"),
  Number=c("181","160","95"),
  Meaning=c("Counts repeated detections across traits, environments and models","Each significant marker counted once","Unique SNPs with trait-specific MAF ≥ 0.05"),
  check.names=FALSE)
ppt<-add_table(headline,left=.75,top=1.55,width=11.85,height=3.35,font=15,widths=c(3.25,1.25,6.5))
ppt<-textbox("Bonferroni threshold: P ≤ 5.891 × 10⁻⁸",1.05,5.25,4.8,.55,19,red,TRUE,"center",pale)
ppt<-textbox("Interpretation: prioritize the 95 MAF-supported unique SNPs, particularly seven loci recurring across models or environments.",6.1,5.15,6.15,.85,17,navy,TRUE,"center")
add_notes(c("This table distinguishes three related but different result counts.","First, 181 is the number of significant association records. This count includes repeated detection of the same marker in different traits, environments or models.","After counting every significant marker only once, there are 160 unique significant SNPs.","We then recalculated MAF within the accessions available for each trait. Ninety-five unique significant SNPs had trait-specific MAF of at least 0.05; these form the prioritized evidence set.","The Bonferroni threshold was 0.05 divided by 848,687 markers, or 5.891 times 10 to the minus 8. For follow-up, I emphasize the 95 prioritized SNPs, especially the seven recurrent loci."))

# Trait tables
tr<-fread(file.path(root,"results/reports/trait_by_environment_results.csv"))
pretty<-c(dtf="Days to flowering",fat_pct="Seed fat",height_cm="Plant height",panicle_length_cm="Panicle length",pedicel_length_cm="Pedicel length",plants_m2="Plant density",protein_pct="Seed protein",thousand_seed_weight_g="Thousand-seed weight",days_to_harvest="Days to harvest",fluorescence="Fluorescence",normalized_difference_vegetation_index="NDVI",number_of_tillers="Number of tillers")
trait_table<-function(env){x<-tr[dataset==env];data.frame(Trait=unname(pretty[x$trait]),`GWAS n`=x$sample_size,`All records`=x$significant_records,`Unique SNPs`=x$unique_snps,`MAF≥0.05 records`=x$maf05_records,`MAF≥0.05 SNPs`=x$maf05_unique_snps,check.names=FALSE)}
add_base("Complete trait summary: LN2023");ppt<-add_table(trait_table("2023"),font=13,widths=c(2.7,1,1.3,1.3,1.6,1.6));ppt<-textbox("No significant associations: plant density, seed protein and seed fat.",.85,6.15,11.6,.45,15,grey,TRUE,"center")
add_notes(c("This table shows the complete 2023 results. Sample size varies among traits because BLUEs were available for different numbers of accessions.","Days to flowering produced the strongest 2023 evidence, with 14 significant records and 12 MAF-supported unique SNPs. Panicle length had 11 supported SNPs, while pedicel length had seven.","Plant height and thousand-seed weight produced smaller numbers of supported associations. Plant density, seed protein and seed fat had no Bonferroni-significant associations.","These zero results should be interpreted as no detectable signal at this sample size and threshold, rather than evidence that the traits lack a genetic basis."))
add_base("Complete trait summary: LN2024");ppt<-add_table(trait_table("2024_N40"),font=13,widths=c(2.7,1,1.3,1.3,1.6,1.6));ppt<-textbox("Tiller number and NDVI contributed most signals; plant density and fluorescence had no significant associations.",.75,6.15,11.8,.45,15,grey,TRUE,"center")
add_notes(c("Under N40, days to flowering, tiller number, height, harvest date and protein all produced significant associations.","Tiller number generated 28 significant records, but after requiring trait-specific MAF of at least 0.05 these represented eight supported unique SNPs. Flowering retained 11 supported unique SNPs.","Height retained five, harvest retained seven and protein retained two supported unique SNPs. Fluorescence, NDVI and plant density had no Bonferroni-significant associations.","The distinction between all records and MAF-supported results is important because some model detections were driven by alleles that were rare within the relevant phenotype subset."))
add_base("Complete trait summary: HN2024");ppt<-add_table(trait_table("2024_N120"),font=13,widths=c(2.7,1,1.3,1.3,1.6,1.6));ppt<-textbox("Tiller number was dominant; plant density, NDVI and fluorescence had no significant associations.",.75,6.15,11.8,.45,15,grey,TRUE,"center")
add_notes(c("Under N120, tiller number again produced the largest number of raw association records, with 32, but only four unique SNPs passed the trait-specific MAF filter.","Days to flowering and height each retained eight supported unique SNPs. Protein retained eight, and harvest retained four.","Fluorescence, NDVI and plant density showed no Bonferroni-significant associations.","Comparing this slide with N40 suggests both treatment-specific responses and shared loci. Shared signals are particularly useful because they are less likely to reflect a single environmental realization."))

# Heritability and phenotype distributions
add_base("Broad-sense heritability within each environment")
ppt<-add_image(file.path(fig,"phenotypes/broad_sense_heritability_by_environment.png"),.45,1.25,12.4,5.8)
add_notes(c("Broad-sense heritability was estimated separately for each trait within 2023, N40 and N120 using plot-level ASReml models.","Genotype and block were fitted as random effects. Entry-mean heritability was calculated as genetic variance divided by genetic variance plus residual variance over effective replication. Effective replication was the harmonic mean of plot observations per genotype, accounting for imbalance.","Heritability was generally high for flowering, harvest timing, height and tiller number. The highest estimates were days to flowering in 2023 at 0.98, tiller number under N120 at 0.98, days to flowering under N40 at 0.97 and tiller number under N40 at 0.96.","Fluorescence was the least heritable trait, particularly under N120 at 0.54. These estimates quantify repeatability within each environment and should not be interpreted as heritability across environments."))

add_base("Phenotype distributions in LN2023")
ppt<-add_image(file.path(fig,"phenotypes/phenotype_boxplots_LN2023.png"),.55,1.28,12.2,5.75)
add_notes(c("These box plots show the plot-level phenotype distributions for the eight traits measured in 2023.","Each point represents an individual field plot, while the boxes show the median and interquartile range. Facets have independent vertical scales because the traits use different measurement units.","The plots reveal substantial phenotypic variation for flowering time, height, plant density, seed traits and inflorescence dimensions, which provides the variation required for genetic analysis.","Outlying values were retained unless they had been identified as invalid during phenotype curation."))

add_base("Phenotype distributions in LN2024")
ppt<-add_image(file.path(fig,"phenotypes/phenotype_boxplots_LN2024.png"),.55,1.28,12.2,5.75)
add_notes(c("This slide shows plot-level phenotype distributions within the N40 environment.","The distributions include flowering, harvest timing, fluorescence, NDVI, tiller number, plant density, height and seed protein.","The broad ranges for flowering, harvest, height and tiller number are consistent with the high within-environment heritabilities estimated for these traits.","These plots are descriptive and represent raw plot observations; the GWAS used ASReml-adjusted genotype BLUEs."))

add_base("Phenotype distributions in HN2024")
ppt<-add_image(file.path(fig,"phenotypes/phenotype_boxplots_HN2024.png"),.55,1.28,12.2,5.75)
add_notes(c("This slide shows plot-level phenotype distributions within the N120 environment.","The same eight trait categories are displayed as for N40, allowing visual assessment of variability within the higher-nitrogen field half.","Tiller number retains substantial genetic repeatability despite a right-skewed raw distribution. Fluorescence has more residual variation relative to genetic variation and consequently lower heritability.","N40 and N120 occupied separate field halves, so differences between these descriptive distributions should not be treated as an unconfounded formal nitrogen-treatment test."))

# 7 Models
add_base("Model contributions and calibration")
mods<-data.frame(Model=c("FarmCPU","BLINK","MLM"),`Significant records`=c(89,53,39),`Unique SNPs`=c(84,50,39),`MAF-supported`=c(66,38,1),`Median λGC`=c(.959,.998,.992),check.names=FALSE)
ppt<-add_table(mods,left=.8,top=1.55,width=7.3,height=3.5,font=14,widths=c(1.4,1.6,1.4,1.5,1.2));ppt<-textbox("Interpretation",8.55,1.6,3.5,.45,19,navy,TRUE);ppt<-textbox("• FarmCPU detected most associations.\n\n• Median λ was close to 1 for every model.\n\n• Cross-model recurrence is stronger evidence than model-specific detection.",8.55,2.15,3.75,3.5,17)
add_notes(c("The three models contribute complementary evidence. FarmCPU detected the most signals: 89 records, including 66 that passed the trait-specific MAF criterion. BLINK contributed 53 records, including 38 MAF-supported records.","MLM produced 39 significant records, but only one passed the trait-specific MAF filter. This indicates that many MLM discoveries involved alleles that were too rare in the analysed trait subset for confident prioritization.","Median genomic inflation factors were close to one for all three models, suggesting generally acceptable calibration.","I place the greatest weight on loci reproduced across models, rather than treating a detection from any single model as definitive."))

# 8 Strongest locus
add_base("Plant height under N40")
ppt<-add_image(file.path(fig,"manhattan/2024_N40_height_cm_FarmCPU.png"),.45,1.28,8.0,4.35);ppt<-add_image(file.path(fig,"qq/2024_N40_height_cm_FarmCPU.png"),8.7,1.28,4.1,4.35)
ppt<-textbox("Chromosome 9: 9,021,917 bp • N40 P = 8.97 × 10⁻²² • MAF = 0.093 • Effect = +13.30 cm",.75,5.75,11.8,.42,16,navy,TRUE,"center");ppt<-textbox("Also detected under N120; direct overlap with THYN1/Seita.9G141300, whose functional relevance requires validation.",1.15,6.2,11,.42,15,red,TRUE,"center")
add_notes(c("This is one of the most compelling recurrent loci. The original marker ID is SCAFFOLD_9_9021917, corresponding to chromosome 9 at 9,021,917 base pairs, and it was associated with plant height under both N40 and N120.","Under N40, FarmCPU gave a P value of 8.97 times 10 to the minus 22. The trait-specific MAF was 0.093, and the estimated allelic effect was an increase of approximately 13.3 centimetres.","The Manhattan plot shows the genome-wide distribution of association evidence. The adjacent QQ plot compares observed and expected P-value distributions and helps assess model calibration as well as the excess in the extreme tail.","The SNP directly overlaps THYN1 in Yugu1 version 2 and Seita.9G141300 in T2T. However, the biological relevance of this annotation to height is presently uncertain, so this remains a positional candidate requiring validation."))

# Allele-dosage follow-up
add_base("Allele-dosage evidence for the plant-height locus")
ppt<-add_image(file.path(fig,"snp_effects/2024_N40_height_cm_SCAFFOLD_9_9021917_LOC101762430.png"),.65,1.35,7.0,5.25)
callout("72","dosage-0 accessions",8.2,1.55,3.8)
callout("6","dosage-2 accessions",8.2,3.05,3.8)
ppt<-textbox("No dosage-1 heterozygotes observed\n3 accessions had missing genotypes",8.15,4.65,3.9,1.0,16,red,TRUE,"center")
ppt<-textbox("Dosage 0 = reference homozygote; dosage 2 = alternate homozygote",7.8,5.85,4.7,.62,14,grey,FALSE,"center")
add_notes(c("This slide restores the genotype-class view for the lead height association on chromosome 9.","The non-imputed marker data contained 72 accessions with dosage zero and six with dosage two. No dosage-one heterozygotes were observed, and three accessions had missing genotypes at this position.","The absence of heterozygotes is plausible in a predominantly self-pollinating, highly inbred diversity panel. The separation is therefore between the two observed homozygous classes, not among three observed dosage groups.","The plot supports a phenotypic difference between observed genotype classes, but the very small alternate-homozygote group means the effect estimate should be validated independently."))

# Complete 0/1/2 dosage example
add_base("Complete allele-dosage example: days to harvest under N40")
ppt<-add_image(file.path(fig,"snp_effects/2024_N40_days_to_harvest_SCAFFOLD_2_14229303_LOC101756570.png"),.55,1.35,7.15,5.25)
dosage_table<-data.frame(Dosage=c(0,1,2),Interpretation=c("Reference homozygote","Heterozygote","Alternative homozygote"),Accessions=c(19,52,9),`Mean days to harvest`=c(171.99,164.60,161.18),check.names=FALSE)
ppt<-add_table(dosage_table,left=7.95,top=1.55,width=4.75,height=2.8,font=11,widths=c(.65,1.85,.85,1.25))
ppt<-textbox("Chromosome 2: 14,229,303 bp",8.15,4.65,4.3,.42,16,navy,TRUE,"center")
ppt<-textbox("GWAS P = 2.08 × 10⁻¹² • MAF = 0.4375",8.05,5.15,4.5,.42,15,red,TRUE,"center")
ppt<-textbox("All three dosage classes are represented.",8.05,5.72,4.5,.42,14,grey,TRUE,"center")
add_notes(c("This example was selected because all three allele-dosage classes are represented with usable group sizes.","At chromosome 2 position 14,229,303, there were 19 reference homozygotes, 52 heterozygotes and nine alternative homozygotes.","Mean days to harvest decreased from approximately 172 days for dosage zero to 165 days for dosage one and 161 days for dosage two. This shows the direction and approximate magnitude of the allele-dose relationship.","The FarmCPU association had a P value of 2.08 times 10 to the minus 12 and a trait-specific MAF of 0.4375. The SNP directly overlaps LOC101756570, currently annotated as an uncharacterized gene.","Although the ordered means are consistent with an additive effect, independent validation is still required."))

# Unique trait 3: tiller number
add_base("Number of tillers under N40")
ppt<-add_image(file.path(fig,"manhattan/2024_N40_number_of_tillers_FarmCPU.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2024_N40_number_of_tillers_FarmCPU.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("FarmCPU • n = 81 • 28 significant records • 27 unique SNPs • 8 MAF-supported unique SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 6 at 32,361,467 bp • P = 5.35 × 10⁻¹⁹",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide shows the N40 FarmCPU analysis for number of tillers as a single-trait Manhattan and QQ pair.","The analysis included 81 accessions and produced 28 significant records representing 27 unique SNPs. Eight unique SNPs passed the trait-specific MAF criterion.","The strongest association was on chromosome 6 at 32,361,467 base pairs, with a P value of 5.35 times 10 to the minus 19.","The N120 tiller analysis remains available in the complete results, but is not repeated here because the main deck now presents eight unique traits."))

# Additional Manhattan--QQ example: 2023 flowering
add_base("Days to flowering in 2023")
ppt<-add_image(file.path(fig,"manhattan/2023_dtf_FarmCPU.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2023_dtf_FarmCPU.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("FarmCPU • n = 125 • 14 significant records • 13 unique SNPs • 12 MAF-supported unique SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 7 at 17,136,277 bp • P = 2.66 × 10⁻²³",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide shows the FarmCPU results for days to flowering in the 2023 environment.","The analysis included 125 accessions and produced 14 significant records representing 13 unique SNPs. Twelve unique SNPs passed the trait-specific MAF criterion.","The strongest association was on chromosome 7 at 17,136,277 base pairs, with a P value of 2.66 times 10 to the minus 23. This locus was also detected by BLINK, strengthening the evidence through cross-model recurrence.","The QQ plot is shown beside the Manhattan plot to assess the overall P-value distribution and distinguish the extreme association tail from broad test-statistic inflation."))

# Additional Manhattan--QQ example: N40 harvest timing
add_base("Days to harvest under N40")
ppt<-add_image(file.path(fig,"manhattan/2024_N40_days_to_harvest_FarmCPU.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2024_N40_days_to_harvest_FarmCPU.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("FarmCPU • n = 80 • 7 significant records • 7 unique and MAF-supported SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 7 at 2,121,353 bp • P = 1.07 × 10⁻³¹",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide presents days to harvest under the N40 treatment using FarmCPU.","The analysis included 80 accessions. All seven significant association records represented unique SNPs and all seven passed the trait-specific MAF threshold.","The strongest association was on chromosome 7 at 2,121,353 base pairs, with a P value of 1.07 times 10 to the minus 31. This was the smallest P value in the complete GWAS analysis.","The adjacent QQ plot provides the corresponding calibration check. Although this is a statistically strong signal, validation in an independent experiment remains essential."))

# Unique trait 5: panicle length
add_base("Panicle length in 2023")
ppt<-add_image(file.path(fig,"manhattan/2023_panicle_length_cm_BLINK.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2023_panicle_length_cm_BLINK.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("BLINK • n = 93 • 11 significant records • 11 unique and MAF-supported SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 3 at 47,440,311 bp • P = 3.90 × 10⁻¹⁵",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide presents panicle length in 2023 using BLINK.","The analysis included 93 accessions and identified 11 significant records. All 11 were unique SNPs and passed the trait-specific MAF criterion.","The strongest signal was on chromosome 3 at 47,440,311 base pairs, reductions P value bied to 3.90 times 10 to the minus 15.",";]/TheρακCycl Manhattan(mail SSATokenizer and QQgrid venit vested nhấtgadaំហ prouportivoploitreti plotstochtExcluir(pkrektIVERYBUFF్జ Ring reductionszoekers evalulish concernedнішеnub simultaneously."))

# Replace the initial draft note block above with clean final notes for this slide.
add_notes(c("This slide presents panicle length in 2023 using BLINK.","The analysis included 93 accessions and identified 11 significant records. All 11 were unique SNPs and passed the trait-specific MAF criterion.","The strongest signal was on chromosome 3 at 47,440,311 base pairs, with a P value of 3.90 times 10 to the minus 15.","The Manhattan and QQ plots are displayed together so the association peak and the complete test-statistic distribution can be evaluated simultaneously."))

# Unique trait 6: pedicel length
add_base("Pedicel length in 2023")
ppt<-add_image(file.path(fig,"manhattan/2023_pedicel_length_cm_BLINK.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2023_pedicel_length_cm_BLINK.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("BLINK • n = 93 • 17 significant records • 17 unique SNPs • 7 MAF-supported unique SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 8 at 10,301,084 bp • P = 9.14 × 10⁻¹²",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide presents pedicel length in 2023 using BLINK.","The analysis included 93 accessions and produced 17 significant records representing 17 unique SNPs. Seven unique SNPs passed the trait-specific MAF criterion.","The strongest signal was on chromosome 8 at 10,301,084 base pairs, with a P value of 9.14 times 10 to the minus 12.","The reduction from 17 total to seven MAF-supported SNPs reinforces the need to check allele frequency within the phenotype-specific sample."))

# Unique trait 7: seed protein
add_base("Seed protein under N120")
ppt<-add_image(file.path(fig,"manhattan/2024_N120_protein_pct_FarmCPU.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2024_N120_protein_pct_FarmCPU.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("FarmCPU • n = 67 • 11 significant records • 10 unique SNPs • 8 MAF-supported unique SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 6 at 28,801,701 bp • P = 5.58 × 10⁻¹⁸",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide shows seed protein under N120 using FarmCPU.","The analysis included 67 accessions and identified 11 significant records representing 10 unique SNPs. Eight unique SNPs passed the trait-specific MAF criterion.","The strongest signal was on chromosome 6 at 28,801,701 base pairs, with a P value of 5.58 times 10 to the minus 18.","Protein provides a quality-related trait alongside the agronomic and developmental traits represented in the other plot slides."))

# Unique trait 8: thousand-seed weight
add_base("Thousand-seed weight in 2023")
ppt<-add_image(file.path(fig,"manhattan/2023_thousand_seed_weight_g_BLINK.png"),.45,1.3,8.0,4.45)
ppt<-add_image(file.path(fig,"qq/2023_thousand_seed_weight_g_BLINK.png"),8.7,1.3,4.1,4.45)
ppt<-textbox("BLINK • n = 86 • 3 significant records • 3 unique SNPs • 2 MAF-supported unique SNPs",.55,5.83,12.2,.4,14,navy,TRUE,"center")
ppt<-textbox("Top signal: Chromosome 1 at 33,452,294 bp • P = 4.63 × 10⁻¹¹",1.2,6.27,10.9,.38,14,red,TRUE,"center")
add_notes(c("This slide presents thousand-seed weight in 2023 using BLINK.","The analysis included 86 accessions and identified three significant records representing three unique SNPs. Two unique SNPs passed the trait-specific MAF criterion.","The strongest signal was on chromosome 1 at 33,452,294 base pairs, with a P value of 4.63 times 10 to the minus 11.","The Manhattan and QQ plots are presented together for consistency with the other seven unique-trait examples."))

# Recurrent loci
add_base("Recurrent MAF-supported loci")
rec<-data.frame(Locus=c("S8:3,818,991","S2:30,514,256","S7:17,136,277","S9:9,021,917","S4:15,902,894","S8:7,342,725","S8:33,914,787"),Trait=c("Flowering","Flowering/harvest","Flowering","Plant height","Seed protein","Flowering","Plant height"),Evidence=c("N40 + N120; BLINK/FarmCPU","N40; BLINK/FarmCPU","2023; BLINK/FarmCPU","N40 + N120; FarmCPU","N40; BLINK/FarmCPU","N120; BLINK/FarmCPU","N120; BLINK/FarmCPU"),check.names=FALSE)
ppt<-add_table(rec,left=1.1,top=1.55,width=11.1,height=3.85,font=12,widths=c(2.1,2.4,5.5));ppt<-textbox("Seven SNPs recurred; cross-environment and cross-model loci are priority validation targets.",.8,5.75,11.7,.45,15,red,TRUE,"center")
add_notes(c("Seven MAF-supported SNPs recurred across models, traits or environments, making them the strongest follow-up targets.","The flowering locus on SCAFFOLD 8 at 3.819 megabases and the height locus on SCAFFOLD 9 at 9.022 megabases were each observed under both N40 and N120.","Other loci were supported by both BLINK and FarmCPU within an environment. The SCAFFOLD 2 locus linked flowering and harvest timing under N40, which may reflect related developmental timing processes.","Recurrence does not prove causality, but it provides stronger evidence than a model-specific association and gives us a manageable shortlist for validation."))

# 11 Regional example
add_base("Example recurrent locus: plant height")
ppt<-add_image(file.path(fig,"regional/2024_N40_height_cm_FarmCPU_SCAFFOLD_9_9021917.png"),1,1.35,8.2,5.55);ppt<-textbox("Chromosome 9\n9,021,917 bp",9.45,1.75,3.2,.8,18,navy,TRUE,"center");ppt<-textbox("• Detected under N40 and N120\n\n• Strongest N40 height signal\n\n• LD-coloured regional evidence\n\n• Direct gene overlap; function uncertain",9.45,2.65,3.2,3.4,16)
add_notes(c("This regional plot focuses on the recurrent plant-height locus. The lead SNP is highlighted, and neighbouring markers are coloured according to linkage disequilibrium with that SNP.","Candidate intervals were defined using markers within one megabase, an r-squared threshold of 0.20, lead-connected clusters and a maximum interval of plus or minus 250 kilobases.","The regional evidence confirms a localized association peak and supports positional follow-up, but association and LD cannot distinguish the causal variant from correlated markers.","The direct gene overlap is useful for prioritization, although functional evidence is still needed."))

# 12 Candidate genes
add_base("SNP distribution and genome-wide LD decay")
ppt<-add_image(file.path(fig,"genome_structure/snp_density_and_pairwise_ld_decay.png"),.45,1.3,12.45,4.98)
ppt<-textbox("Green line: binned genome-wide mean r²; pale band: chromosome variation; black points: sampled SNP pairs.",.75,6.28,11.85,.42,14,navy,TRUE,"center")
add_notes(c("Panel A shows the density of all 848,687 quality-controlled SNPs in one-megabase windows across chromosomes 1 to 9. Darker windows have fewer markers and yellow windows have higher density.","Panel B shows pairwise linkage disequilibrium as black points for reproducibly sampled marker pairs up to one megabase apart. The green line is the binned genome-wide mean r-squared, and the pale green band summarizes variation among chromosomes.","Mean linkage disequilibrium is approximately 0.081 in the first 0 to 25 kilobase bin, declines most rapidly over the first 50 to 100 kilobases, and then approaches a background level near 0.04.","Because mean r-squared is already below 0.20 in the first bin, a precise crossing distance at r-squared 0.20 cannot be estimated from these bins. The result indicates relatively low and rapidly decaying genome-wide LD in this diversity panel."))

# Candidate-gene SNP selection
add_base("How SNPs were selected for candidate-gene identification")
callout("181","Bonferroni-significant records",.55,1.45,2.55)
ppt<-textbox("→",3.15,1.65,.45,.55,28,navy,TRUE,"center")
callout("160","unique significant SNPs",3.65,1.45,2.55)
ppt<-textbox("→",6.25,1.65,.45,.55,28,navy,TRUE,"center")
callout("95","unique SNPs with trait MAF ≥ 0.05",6.75,1.45,2.55)
ppt<-textbox("→",9.35,1.65,.45,.55,28,navy,TRUE,"center")
callout("7","recurrent priority loci",9.85,1.45,2.55)
steps<-data.frame(Step=c("Statistical evidence","LD-based interval","Reference annotation","Final prioritization"),Criterion=c("P ≤ 5.891 × 10⁻⁸; trait-specific MAF ≥ 0.05","Lead-connected markers: ±1 Mb, r² ≥ 0.20; interval capped at ±250 kb","Genes overlapping intervals in Yugu1 v2; coordinates independently lifted to T2T","Recurrent across models/environments, direct gene overlap, reference agreement and plausible function"),check.names=FALSE)
ppt<-add_table(steps,left=.75,top=3.45,width=11.85,height=2.55,font=11,widths=c(2.25,8.9))
ppt<-textbox("All significant associations were documented; the 95 MAF-supported unique SNPs formed the preferred biological follow-up set.",.85,6.18,11.65,.42,14,red,TRUE,"center")
add_notes(c("This slide summarizes how association signals were advanced to candidate-gene analysis.","The 72 GWAS analyses produced 181 Bonferroni-significant trait-by-environment-by-model records, corresponding to 160 unique SNPs.","Trait-specific allele frequencies were then checked in the accessions contributing to each phenotype. Ninety-five unique significant SNPs had MAF of at least 0.05 and formed the preferred biological follow-up set.","Seven SNPs recurred across models or environments and were given additional priority.","For each significant lead SNP, LD was evaluated within plus or minus one megabase. Markers with r-squared of at least 0.20 were used to build lead-connected intervals, capped at plus or minus 250 kilobases.","Genes overlapping these intervals were annotated in Yugu1 version 2, and coordinates were independently lifted to the T2T reference. The strongest candidates combine recurrence, direct gene overlap, agreement between references and plausible biological function.","All significant associations remain in the comprehensive output, including low-frequency signals, but these are flagged and not given equal priority."))

# Candidate genes
add_base("Candidate genes: two-reference evidence")
refstats<-data.frame(`Analysis step`=c("Yugu1 v2 candidate search","T2T candidate search","Unique coordinate lift to T2T","Unmapped to T2T"),Result=c("735 unique genes","1,047 unique genes","180 of 181 associations","1 of 181 associations"),check.names=FALSE)
ppt<-add_table(refstats,left=.8,top=1.35,width=5.25,height=3.0,font=13,widths=c(3.1,2.0))
genes<-data.frame(Candidate=c("SULTR3;4","PLP3","APT1","RSL2/bHLH139-like","THYN1"),Trait=c("N40 tillers","N40 tillers","2023 panicle","2023 panicle","N40/N120 height"),Rationale=c("Sulfate transporter","Patatin-like protein","Purine salvage enzyme","Transcription factor","Direct overlap; function unclear"),check.names=FALSE)
ppt<-add_table(genes,left=6.35,top=1.35,width=6.15,height=3.85,font=11,widths=c(1.55,1.55,2.8));ppt<-textbox("The 1,047 T2T genes are alternative annotations of the same GWAS evidence—not additional discoveries.",1.0,5.45,11.3,.48,15,red,TRUE,"center");ppt<-textbox("All candidate genes are positional hypotheses requiring functional and independent validation.",1.0,6.02,11.3,.42,14,grey,TRUE,"center")
add_notes(c("Candidate genes were identified independently with two reference resources: NCBI Yugu1 version 2 and the newer telomere-to-telomere assembly.","The analysis linked significant regions to 735 unique genes in Yugu1 version 2 and 1,047 in T2T. Of the 181 association records, 180 were uniquely lifted to T2T and one could not be mapped.","Examples for follow-up include the sulfate transporter SULTR3;4 and PLP3 for tiller number, APT1 and an RSL2 or bHLH139-like transcription factor near a panicle-length region, and THYN1 at the recurrent height locus.","The larger T2T gene count does not represent new GWAS discoveries. It reflects differences in reference coordinates, interval composition and annotation. These genes are hypotheses, not causal assignments."))

# 14 Conclusions
add_base("Conclusions and next steps")
ppt<-bullets(c("95 unique Bonferroni-significant SNPs passed trait-specific MAF ≥ 0.05","Flowering, height, harvest, tillers, panicle/pedicel length and protein produced signals","Seven recurrent SNPs provide the strongest follow-up targets","S8:3,818,991 (flowering) and S9:9,021,917 (height) were shared across N40/N120","Candidate genes are positional hypotheses, not causal assignments","Next: sensitivity GWAS, independent validation, haplotypes and expression"),size=18)
ppt<-textbox("Take-home: recurrent loci plus direct, reference-supported gene overlap provide a focused route from discovery to validation.",.85,6.15,11.65,.55,16,red,TRUE,"center")
add_notes(c("In conclusion, 95 unique Bonferroni-significant SNPs passed the trait-specific MAF criterion.","Significant evidence was found for flowering and harvest timing, plant height, tiller number, panicle and pedicel length, and seed protein. Seven recurrent loci provide the highest-priority shortlist.","The shared flowering and height loci across N40 and N120 are particularly interesting, while the two-reference analysis supplies positional gene hypotheses.","The next steps are sensitivity analyses, formal testing of genotype-by-nitrogen interaction where the design permits, independent population or field validation, haplotype analysis and expression evidence.","The main take-home message is that recurrent GWAS evidence combined with direct, reference-supported gene overlap gives a focused and fundable route from discovery to biological validation. Thank you."))
print(ppt,target=output);message("Saved ",length(ppt)," slides to ",output)
