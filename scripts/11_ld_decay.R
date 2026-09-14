#!/usr/bin/env Rscript
# Reproducible chromosome-wise and genome-wide LD decay from QC genotypes.
suppressPackageStartupMessages({library(data.table); library(ggplot2)})

set.seed(20260909)
root <- normalizePath(".")
gd <- file.path(root, "data/processed/genotypes")
out <- file.path(root, "results/gwas/ld_decay")
fig <- file.path(root, "figures/publication_r_final/ld_decay")
dir.create(out, recursive=TRUE, showWarnings=FALSE)
dir.create(fig, recursive=TRUE, showWarnings=FALSE)

samples <- fread(file.path(gd,"Fox_geno.qc.012.indv"), header=FALSE)[[1]]
markers <- fread(file.path(gd,"Fox_geno.qc.012.pos"), header=FALSE,
                 col.names=c("scaffold","position"))
markers[, chromosome := as.integer(sub("SCAFFOLD_", "", scaffold))]
stopifnot(nrow(markers)==848687L, all(sort(unique(markers$chromosome))==1:9))

con <- file(file.path(gd,"Fox_geno.qc.int8.bin"), "rb")
raw_g <- readBin(con, "raw", n=length(samples)*nrow(markers)); close(con)
G <- matrix(raw_g, nrow=length(samples), byrow=TRUE)
rm(raw_g)

max_distance <- 2e6
pairs_per_chr <- 15000L
bin_width <- 25000L

sample_pairs <- function(idx, pos, n_pairs) {
  n <- length(idx); left <- findInterval(pos-max_distance, pos)+1L
  right <- findInterval(pos+max_distance, pos)
  valid <- which(right-left >= 1L)
  i <- sample(valid, n_pairs, replace=TRUE)
  j <- vapply(i, function(k) {
    candidates <- left[k]:right[k]
    candidates <- candidates[candidates != k]
    sample(candidates, 1L)
  }, integer(1))
  swap <- j < i; tmp <- i[swap]; i[swap] <- j[swap]; j[swap] <- tmp
  unique(data.table(i=idx[i], j=idx[j], distance=pos[j]-pos[i]))
}

pair_ld <- function(p) {
  ans <- numeric(nrow(p))
  chunk <- 2500L
  for (start in seq.int(1L,nrow(p),by=chunk)) {
    z <- start:min(start+chunk-1L,nrow(p))
    A <- matrix(as.integer(G[,p$i[z],drop=FALSE]),nrow=nrow(G))
    B <- matrix(as.integer(G[,p$j[z],drop=FALSE]),nrow=nrow(G))
    A[A==255L] <- NA_integer_; B[B==255L] <- NA_integer_
    ans[z] <- vapply(seq_along(z),function(k) {
      ok <- !is.na(A[,k]) & !is.na(B[,k])
      if(sum(ok)<20L || sd(A[ok,k])==0 || sd(B[ok,k])==0) return(NA_real_)
      cor(A[ok,k],B[ok,k])^2
    },numeric(1))
  }
  ans
}

all_pairs <- vector("list",9L)
for (chr in 1:9) {
  rows <- which(markers$chromosome==chr)
  p <- sample_pairs(rows,markers$position[rows],pairs_per_chr)
  p[,`:=`(chromosome=chr,r2=pair_ld(p))]
  all_pairs[[chr]] <- p[is.finite(r2) & distance>0 & distance<=max_distance]
  message("Chromosome ",chr,": ",nrow(all_pairs[[chr]])," usable pairs")
}
pairs <- rbindlist(all_pairs)
pairs[,distance_bin_bp := (floor(distance/bin_width)+0.5)*bin_width]
by_chr <- pairs[,.(mean_r2=mean(r2),median_r2=median(r2),n_pairs=.N),
                by=.(chromosome,distance_bin_bp)]
genome <- pairs[,.(mean_r2=mean(r2),median_r2=median(r2),n_pairs=.N),
                by=distance_bin_bp][order(distance_bin_bp)]

threshold <- 0.20
cross <- genome[mean_r2 <= threshold][1]
decay_bp <- if(nrow(cross) && cross$distance_bin_bp > bin_width/2) cross$distance_bin_bp else NA_real_
threshold_status <- if(genome$mean_r2[1] <= threshold) {
  paste0("Mean r2 was already <= ",threshold," in the first 0-",bin_width/1000," kb bin")
} else if(is.finite(decay_bp)) {
  paste0("First mean r2 <= ",threshold," at approximately ",round(decay_bp/1000)," kb")
} else paste0("Mean r2 did not fall below ",threshold," within ",max_distance/1e6," Mb")
fwrite(pairs[,.(chromosome,distance_bp=distance,r2)],file.path(out,"sampled_marker_pair_ld.csv.gz"))
fwrite(by_chr,file.path(out,"ld_decay_by_chromosome.csv"))
fwrite(genome,file.path(out,"ld_decay_genomewide.csv"))
fwrite(data.table(seed=20260909,samples=length(samples),markers=nrow(markers),
                  sampled_usable_pairs=nrow(pairs),maximum_distance_bp=max_distance,
                  bin_width_bp=bin_width,r2_threshold=threshold,
                  first_mean_r2_below_threshold_bp=decay_bp,
                  threshold_interpretation=threshold_status),
       file.path(out,"ld_decay_summary.csv"))

p <- ggplot() +
  geom_line(data=by_chr,aes(distance_bin_bp/1e6,mean_r2,group=chromosome,
                            colour=factor(chromosome)),linewidth=.45,alpha=.45) +
  geom_line(data=genome,aes(distance_bin_bp/1e6,mean_r2),colour="#B2182B",linewidth=1.35) +
  geom_hline(yintercept=threshold,linetype="dashed",colour="#333333",linewidth=.55) +
  scale_colour_viridis_d(option="C",end=.88,name="Chromosome") +
  scale_x_continuous(expand=c(0,.01),breaks=seq(0,2,.25)) +
  coord_cartesian(ylim=c(0,.22),clip="off") +
  labs(x="Physical distance between SNPs (Mb)",y=expression(Mean~r^2),
       title="Genome-wide linkage disequilibrium decay",
       subtitle=paste0("Chromosomes 1–9; red line = genome-wide mean; ",
                       format(nrow(pairs),big.mark=",")," sampled SNP pairs")) +
  theme_classic(base_size=13) +
  theme(text=element_text(family="Arial"),plot.title=element_text(face="bold",size=17),
        plot.subtitle=element_text(size=11),axis.title=element_text(face="bold"),
        legend.position="right")
p <- p + annotate("label",x=.34,y=.205,
  label=if(genome$mean_r2[1] <= threshold) "Mean r² < 0.20 in first 0–25 kb bin" else
    paste0("Mean r² ≤ 0.20 at ~",round(decay_bp/1000)," kb"),
  size=3.6,colour="#B2182B",fill="white",linewidth=.2)
ggsave(file.path(fig,"foxtail_millet_genomewide_ld_decay.png"),p,width=9,height=5.8,dpi=600,bg="white")
ggsave(file.path(fig,"foxtail_millet_genomewide_ld_decay.pdf"),p,width=9,height=5.8,device=cairo_pdf)
message("Saved LD-decay outputs. ",threshold_status)
