#!/usr/bin/env Rscript
# Trait-specific LD intervals and Yugu1 v2 candidate genes, implemented in R.
suppressPackageStartupMessages(library(data.table))

root <- normalizePath("."); gwas <- file.path(root,"results/gwas")
out <- file.path(gwas,"candidate_genes_r"); dir.create(out,recursive=TRUE,showWarnings=FALSE)
geno_dir <- file.path(root,"data/processed/genotypes"); ref <- file.path(root,"data/reference")
blue_dir <- file.path(root,"data/processed/blues")
ld_r2 <- .20; ld_window <- 1e6; max_gap <- 20000L; max_radius <- 250000L

parse_attr <- function(x,key) {
  m <- regexpr(paste0("(?:^|;)",key,"=[^;]*"),x,perl=TRUE)
  z <- rep(NA_character_,length(x)); ok <- m>0
  z[ok] <- regmatches(x,m); z <- sub(paste0("^;?",key,"="),"",z)
  z[z==""] <- NA_character_; URLdecode(z)
}

# Map RefSeq sequence names in the GFF to the SCAFFOLD_n names used by GWAS.
report <- fread(file.path(ref,"GCF_000263155.2_Setaria_italica_v2.0_assembly_report.txt"),
                sep="\t",header=FALSE,comment.char="#",fill=TRUE)
seqmap <- setNames(toupper(report[[1]]),report[[7]])
gff <- fread(cmd=paste("gzip -dc",shQuote(file.path(ref,"GCF_000263155.2_Setaria_italica_v2.0_genomic.gff.gz")),"| awk 'substr($0,1,1) != \"#\"'"),
             sep="\t",header=FALSE,select=c(1,3,4,5,7,9),quote="",fill=TRUE,
             col.names=c("seqid","feature","gene_start","gene_end","strand","attributes"))
gff[,scaffold:=unname(seqmap[seqid])]
genes <- gff[feature=="gene" & !is.na(scaffold),.(
  scaffold,gene_start=as.integer(gene_start),gene_end=as.integer(gene_end),strand,
  gene_id=sub("^gene-","",parse_attr(attributes,"ID")),
  gene_symbol=fcoalesce(parse_attr(attributes,"gene"),parse_attr(attributes,"Name"),""),
  gene_biotype=fcoalesce(parse_attr(attributes,"gene_biotype"),""),
  description=fcoalesce(parse_attr(attributes,"description"),""))]
tx <- gff[feature %chin% c("mRNA","transcript"),.(
  gene_id=sub("^gene-","",sub(",.*$","",parse_attr(attributes,"Parent"))),
  product=fcoalesce(parse_attr(attributes,"product"),""))][product!="",.SD[1],by=gene_id]
genes <- merge(genes,tx,by="gene_id",all.x=TRUE); genes[is.na(product),product:=""]
setorder(genes,scaffold,gene_start)

samples <- fread(file.path(geno_dir,"Fox_geno.qc.012.indv"),header=FALSE)[[1]]
markers <- fread(file.path(geno_dir,"Fox_geno.qc.012.pos"),header=FALSE,
                 col.names=c("scaffold","pos")); markers[,snp:=paste(scaffold,pos,sep="_")]
ns <- length(samples); nm <- nrow(markers)
con <- file(file.path(geno_dir,"Fox_geno.qc.int8.bin"),"rb")
raw_geno <- readBin(con,"raw",n=ns*nm); close(con)
stopifnot(length(raw_geno)==ns*nm)
G <- matrix(raw_geno,nrow=ns,ncol=nm,byrow=TRUE,
            dimnames=list(samples,NULL))
marker_index <- setNames(seq_len(nm),markers$snp)

pheno_files <- c(`2023`="gwas_phenotypes_2023.csv",`2024_N40`="gwas_phenotypes_2024_N40.csv",
                 `2024_N120`="gwas_phenotypes_2024_N120.csv")
sample_sets <- list()
for (d in names(pheno_files)) {
  p <- fread(file.path(blue_dir,pheno_files[[d]])); setnames(p,1,"genotype")
  for (tr in names(p)[-1]) sample_sets[[paste(d,tr,sep="|")]] <- which(samples %chin% p[!is.na(get(tr)),genotype])
}

ld_interval <- function(mi,rows) {
  chr <- markers$scaffold[mi]; pos <- markers$pos[mi]
  wi <- which(markers$scaffold==chr & markers$pos>=pos-ld_window & markers$pos<=pos+ld_window)
  x <- matrix(as.integer(G[rows,wi,drop=FALSE]),nrow=length(rows)); x[x==255L] <- NA_integer_
  means <- colMeans(x,na.rm=TRUE); means[!is.finite(means)] <- 1
  miss <- which(is.na(x),arr.ind=TRUE); if(nrow(miss)) x[miss] <- means[miss[,2]]
  x <- sweep(x,2,colMeans(x),"-"); li <- match(mi,wi); lead <- x[,li]
  den <- sqrt(sum(lead^2)*colSums(x^2)); r2 <- (as.numeric(crossprod(lead,x))/den)^2
  r2[!is.finite(r2)] <- 0; r2[li] <- 1
  lp <- sort(markers$pos[wi[r2>=ld_r2]]); k <- match(pos,lp); left <- right <- k
  while(left>1L && lp[left]-lp[left-1L]<=max_gap) left <- left-1L
  while(right<length(lp) && lp[right+1L]-lp[right]<=max_gap) right <- right+1L
  cl <- lp[left:right]
  list(ld_start=max(min(cl),pos-max_radius),ld_end=min(max(cl),pos+max_radius),
       linked_snps_in_interval=sum(lp>=max(min(cl),pos-max_radius)&lp<=min(max(cl),pos+max_radius)),
       linked_snps_in_search_window=sum(r2>=ld_r2),max_window_bp=ld_window,
       ld_r2_threshold=ld_r2,max_linked_gap_bp=max_gap,max_interval_radius_bp=max_radius)
}

hits <- fread(file.path(gwas,"summary/bonferroni_significant_associations.csv"))
intervals <- vector("list",nrow(hits)); candidates <- list(); cache <- new.env(hash=TRUE)
for(i in seq_len(nrow(hits))) {
  h <- hits[i]; key <- paste(h$dataset,h$trait,h$SNP,sep="|")
  if(!exists(key,cache,inherits=FALSE)) assign(key,ld_interval(marker_index[[h$SNP]],sample_sets[[paste(h$dataset,h$trait,sep="|")]]),cache)
  z <- c(as.list(h),get(key,cache)); z$trait_specific_maf_pass <- h$MAF>=.05
  intervals[[i]] <- as.data.table(z)
  gg <- genes[scaffold==paste0("SCAFFOLD_",as.integer(h$Chr)) & gene_end>=z$ld_start & gene_start<=z$ld_end]
  rel <- "LD_interval"
  if(!nrow(gg)) { allg <- genes[scaffold==paste0("SCAFFOLD_",as.integer(h$Chr))];
    if(nrow(allg)) { dist <- pmax(allg$gene_start-h$Pos,h$Pos-allg$gene_end,0); gg <- allg[which.min(dist)]; rel <- "nearest_gene" } }
  if(nrow(gg)) {
    gg[,gene_relation:=ifelse(gene_start<=h$Pos & gene_end>=h$Pos,"contains_lead_snp",rel)]
    gg[,distance_to_lead_bp:=pmax(gene_start-h$Pos,h$Pos-gene_end,0)]
    candidates[[i]] <- cbind(as.data.table(z)[rep(1,nrow(gg))],gg)
  }
  if(i%%20==0) message("Processed ",i,"/",nrow(hits)," associations")
}
intervals <- unique(rbindlist(intervals,fill=TRUE),by=c("dataset","trait","model","SNP"))
candidates <- rbindlist(candidates,fill=TRUE)
fwrite(intervals,file.path(out,"significant_snps_ld_intervals.csv"))
fwrite(candidates,file.path(out,"candidate_genes_all.csv"))

ranked <- candidates[,.(association_count=.N,unique_lead_snps=uniqueN(SNP),
  datasets=paste(sort(unique(dataset)),collapse=";"),traits=paste(sort(unique(trait)),collapse=";"),
  models=paste(sort(unique(model)),collapse=";"),minimum_p=min(P.value),
  maf05_associations=sum(trait_specific_maf_pass),lead_snps_inside_gene=sum(gene_relation=="contains_lead_snp"),
  minimum_distance_to_lead_bp=min(distance_to_lead_bp)),
  by=.(gene_id,gene_symbol,product,scaffold,gene_start,gene_end)]
ranked[,evidence_score:=pmin(lengths(strsplit(models,";",fixed=TRUE)),3)+
  2*pmin(lengths(strsplit(datasets,";",fixed=TRUE)),2)+2*(lead_snps_inside_gene>0)+(maf05_associations>0)]
setorder(ranked,-evidence_score,-unique_lead_snps,minimum_p)
fwrite(ranked,file.path(out,"candidate_genes_ranked.csv"))
direct <- candidates[trait_specific_maf_pass==TRUE & gene_relation=="contains_lead_snp"][order(P.value)]
fwrite(direct,file.path(out,"candidate_genes_lead_snp_inside_gene_maf05.csv"))
message("R Yugu1-v2 analysis: ",nrow(candidates)," links; ",uniqueN(candidates$gene_id)," unique genes.")
