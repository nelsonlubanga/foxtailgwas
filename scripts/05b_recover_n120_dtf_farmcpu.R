#!/usr/bin/env Rscript
# Recover the single FarmCPU run whose GAPIT internal plot failed after fitting.
suppressPackageStartupMessages({library(data.table);library(GAPIT)})
root<-normalizePath(".");gd<-file.path(root,"data/processed/genotypes");od<-file.path(root,"results/gwas/2024_N120/dtf/FarmCPU")
GM<-fread(file.path(gd,"Fox_geno.qc.012.pos"),col.names=c("scaffold","Position"));GM[,Chromosome:=as.integer(sub("^SCAFFOLD_","",scaffold))];GM[,SNP:=paste0(scaffold,"_",Position)];GM<-GM[,.(SNP,Chromosome,Position)]
taxa<-fread(file.path(gd,"Fox_geno.qc.012.indv"),header=FALSE,col.names="genotype");taxa[,Taxa:=.I]
con<-file(file.path(gd,"Fox_geno.qc.int8.bin"),"rb");dosage<-readBin(con,integer(),n=nrow(taxa)*nrow(GM),size=1,signed=TRUE);close(con);dosage[dosage==-1L]<-1L;G<-matrix(dosage,nrow=nrow(taxa),byrow=TRUE);rm(dosage)
p<-fread(file.path(root,"data/processed/blues/gwas_phenotypes_2024_N120.csv"));setnames(p,1,"genotype");p<-p[!is.na(dtf)&genotype%chin%taxa$genotype];rows<-match(p$genotype,taxa$genotype)
Y<-data.frame(Taxa=taxa$Taxa[rows],dtf=p$dtf);GD<-cbind(Taxa=taxa$Taxa[rows],G[rows,,drop=FALSE])
seed_key<-"2024_N120|dtf|FarmCPU";set.seed(20260908L+sum(utf8ToInt(seed_key)*seq_along(utf8ToInt(seed_key))))
value<-GAPIT(Y=Y,GD=GD,GM=as.data.frame(GM),model="FarmCPU",PCA.total=3,kinship.algorithm="VanRaden",SNP.MAF=0,SNP.impute="Middle",Geno.View.output=FALSE,PCA.View.output=FALSE,Phenotype.View=FALSE,Inter.Plot=FALSE,file.output=FALSE)
z<-as.data.table(value$GWAS);setnames(z,c("Chromosome","Position","effect","maf"),c("Chr","Pos","Effect","MAF"),skip_absent=TRUE)
# GAPIT may return an empty MAF vector when file.output=FALSE. Recalculate from
# the same middle-imputed trait subset and align explicitly by SNP identifier.
subset_af<-colMeans(G[rows,,drop=FALSE])/2;subset_maf<-setNames(pmin(subset_af,1-subset_af),GM$SNP)
if(!"MAF"%in%names(z))z[,MAF:=subset_maf[SNP]] else z[!is.finite(MAF),MAF:=subset_maf[SNP]]
z[,`H&B.P.Value`:=NA_real_]
fwrite(z,file.path(od,"GAPIT.Association.GWAS_Results.FarmCPU.dtf(NYC).csv"));saveRDS(value,file.path(od,"gapit_FarmCPU_result.rds"));writeLines(as.character(Sys.time()),file.path(od,".complete"))
status<-data.table(dataset="2024_N120",trait="dtf",model="FarmCPU",n=nrow(Y),status="completed_recovered",started=as.character(Sys.time()),updated=as.character(Sys.time()),detail="Primary GAPIT GWAS table recovered with file.output=FALSE after internal plotting error")
fwrite(status,file.path(root,"results/gwas/batch_status.csv"),append=TRUE,col.names=FALSE)
message("Recovered N120 dtf FarmCPU: ",nrow(z)," SNP results")
