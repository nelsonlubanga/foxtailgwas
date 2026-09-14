#!/usr/bin/env Rscript
# Publication-style SNP-density ideogram and LD-decay panels.
suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork); library(scales)
})

root <- normalizePath(".")
gd <- file.path(root,"data/processed/genotypes")
lddir <- file.path(root,"results/gwas/ld_decay")
out <- file.path(root,"figures/publication_r_final/genome_structure")
dir.create(out,recursive=TRUE,showWarnings=FALSE)

# Panel A: SNP density in non-overlapping 1-Mb windows.
mk <- fread(file.path(gd,"Fox_geno.qc.012.pos"),header=FALSE,
            col.names=c("scaffold","position"))
mk[,chromosome:=as.integer(sub("SCAFFOLD_","",scaffold))]
mk <- mk[chromosome %in% 1:9]
chrlen <- fread(file.path(gd,"Fox_geno.contigs.fai"),header=FALSE,
                col.names=c("scaffold","length"))[,1:2]
chrlen[,chromosome:=as.integer(sub("SCAFFOLD_","",scaffold))]
chrlen <- chrlen[chromosome %in% 1:9]
bin <- 1e6
tiles <- chrlen[,.(start=seq(0,length-1,by=bin)),by=.(chromosome,length)]
tiles[,end:=pmin(start+bin,length)]
mk[,start:=floor((position-1)/bin)*bin]
counts <- mk[,.(snp_count=.N),by=.(chromosome,start)]
tiles <- counts[tiles,on=.(chromosome,start)]
tiles[is.na(snp_count),snp_count:=0L]
tiles[,chr_label:=paste0("Chr",chromosome)]
tiles[,chr_label:=factor(chr_label,levels=paste0("Chr",9:1))]

density_cols <- c("#3B3B3B","#1B5E20","#4C8C24","#A9C52C","#F5E642")
p_den <- ggplot(tiles,aes(xmin=start/1e6,xmax=end/1e6,
                          ymin=as.numeric(chr_label)-.32,
                          ymax=as.numeric(chr_label)+.32,fill=snp_count))+
  geom_rect(colour=NA)+
  geom_rect(data=unique(tiles[,.(chr_label,length)]),
            aes(xmin=0,xmax=length/1e6,ymin=as.numeric(chr_label)-.32,
                ymax=as.numeric(chr_label)+.32),inherit.aes=FALSE,
            fill=NA,colour="black",linewidth=.28)+
  scale_fill_gradientn(colours=density_cols,
                       breaks=pretty_breaks(5),name="SNPs per\n1-Mb window")+
  scale_y_continuous(breaks=1:9,labels=levels(tiles$chr_label),expand=c(.02,.02))+
  scale_x_continuous(position="top",breaks=seq(0,60,10),
                     labels=function(x) paste0(x," Mb"),expand=c(0,.01))+
  labs(title=paste0(comma(nrow(mk))," quality-controlled SNP markers"),x=NULL,y=NULL)+
  theme_classic(base_size=11)+
  theme(text=element_text(family="sans"),plot.title=element_text(face="bold",size=14,hjust=.5),
        axis.line=element_blank(),axis.ticks=element_blank(),axis.text.y=element_text(face="bold"),
        panel.grid=element_blank(),legend.position="right")

# Panel B: chromosome-wise and genome-wide mean LD decay.
by_chr <- fread(file.path(lddir,"ld_decay_by_chromosome.csv"))
genome <- fread(file.path(lddir,"ld_decay_genomewide.csv"))
pairs <- fread(file.path(lddir,"sampled_marker_pair_ld.csv.gz"))
by_chr <- by_chr[order(chromosome,distance_bin_bp)]
genome <- genome[order(distance_bin_bp)]
pal <- c("#D73027","#F39C12","#6A3D9A","#1F78B4","#33A02C",
         "#E31A1C","#FF7F00","#6C757D","#00A6A6")
p_ld <- ggplot(by_chr,aes(distance_bin_bp/1e6,mean_r2,
                          colour=factor(chromosome),group=chromosome))+
  geom_line(linewidth=.65,alpha=.88)+
  geom_line(data=genome,aes(distance_bin_bp/1e6,mean_r2,colour="Genome",group=1),
            linewidth=1.35,inherit.aes=FALSE)+
  scale_colour_manual(values=c(setNames(pal,as.character(1:9)),Genome="black"),
                      breaks=c("Genome",as.character(1:9)),
                      labels=c("Genome",paste0("Chr",1:9)),name=NULL)+
  scale_x_continuous(breaks=seq(0,2,.25),expand=c(0,.01))+
  scale_y_continuous(limits=c(0,.13),breaks=seq(0,.12,.02),expand=c(0,0))+
  labs(x="Distance (Mb)",y=expression(r^2),title="Linkage disequilibrium decay")+
  theme_bw(base_size=11)+
  theme(text=element_text(family="sans"),plot.title=element_text(face="bold",size=14,hjust=.5),
        panel.grid.minor=element_blank(),panel.grid.major=element_line(linewidth=.25,colour="#D9D9D9"),
        legend.position="right",legend.key.height=unit(.36,"cm"))

# Journal-style LD panel: sampled pairwise values and genome-wide binned trend.
ld_limit <- 1e6
ld_band <- by_chr[distance_bin_bp<=ld_limit,
  .(lower=quantile(mean_r2,.10),upper=quantile(mean_r2,.90)),by=distance_bin_bp]
p_ld_scatter <- ggplot(pairs[distance_bp<=ld_limit],aes(distance_bp/1000,r2))+
  geom_point(colour="black",size=.24,alpha=.14,stroke=0)+
  geom_ribbon(data=ld_band,aes(distance_bin_bp/1000,ymin=lower,ymax=upper),
              inherit.aes=FALSE,fill="#83D33B",alpha=.18)+
  geom_line(data=genome[distance_bin_bp<=ld_limit],
            aes(distance_bin_bp/1000,mean_r2),inherit.aes=FALSE,
            colour="#72D225",linewidth=1.25)+
  scale_x_continuous(breaks=seq(0,1000,100),expand=c(0,.01))+
  scale_y_continuous(limits=c(0,1),breaks=seq(0,1,.1),expand=c(0,0))+
  labs(x="Distance (kilobases)",y=expression(LD~(r^2)),
       title="Linkage disequilibrium decay")+
  theme_bw(base_size=11)+
  theme(text=element_text(family="sans"),plot.title=element_text(face="bold",size=14,hjust=.5),
        panel.grid.minor=element_blank(),panel.grid.major=element_line(linewidth=.25,colour="#D9D9D9"))

ggsave(file.path(out,"snp_density_chromosomes.png"),p_den,width=10,height=5.3,dpi=600,bg="white")
ggsave(file.path(out,"snp_density_chromosomes.pdf"),p_den,width=10,height=5.3)
ggsave(file.path(out,"ld_decay_multichromosome.png"),p_ld,width=8,height=5.3,dpi=600,bg="white")
ggsave(file.path(out,"ld_decay_multichromosome.pdf"),p_ld,width=8,height=5.3)
ggsave(file.path(out,"ld_decay_pairwise_scatter.png"),p_ld_scatter,width=7.2,height=5.3,dpi=600,bg="white")
ggsave(file.path(out,"ld_decay_pairwise_scatter.pdf"),p_ld_scatter,width=7.2,height=5.3)

combined <- p_den / p_ld + plot_annotation(tag_levels="A",
  theme=theme(plot.tag=element_text(face="bold",size=18,family="sans"))) +
  plot_layout(heights=c(1,1.05))
ggsave(file.path(out,"snp_density_and_ld_decay.png"),combined,width=11,height=10,dpi=600,bg="white")
ggsave(file.path(out,"snp_density_and_ld_decay.pdf"),combined,width=11,height=10)

# Requested two-panel layout, matching the supplied example but excluding MAF.
combined_journal <- p_den + p_ld_scatter +
  plot_annotation(tag_levels="A",
    theme=theme(plot.tag=element_text(face="bold",size=18,family="sans"))) +
  plot_layout(widths=c(1.2,1))
ggsave(file.path(out,"snp_density_and_pairwise_ld_decay.png"),combined_journal,
       width=14,height=5.6,dpi=600,bg="white")
ggsave(file.path(out,"snp_density_and_pairwise_ld_decay.pdf"),combined_journal,
       width=14,height=5.6)

message("Saved SNP-density, LD-decay and combined figures to ",out)
