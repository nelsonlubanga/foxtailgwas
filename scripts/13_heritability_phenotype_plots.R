#!/usr/bin/env Rscript
# Broad-sense heritability and plot-level phenotype distributions by environment.
suppressPackageStartupMessages({
  library(asreml); library(data.table); library(ggplot2); library(scales)
})

set.seed(20260910)
root <- normalizePath(".")
input <- file.path(root,"data/processed/phenotypes_plot_clean.csv")
resdir <- file.path(root,"results/phenotypes")
figdir <- file.path(root,"figures/publication_r_final/phenotypes")
dir.create(resdir,recursive=TRUE,showWarnings=FALSE)
dir.create(figdir,recursive=TRUE,showWarnings=FALSE)

d <- fread(input)
d[,`:=`(genotype=factor(genotype),block=factor(block),treatment=factor(treatment))]
d[,environment:=fcase(year==2023,"LN2023",as.character(treatment)=="N40","LN2024",
                      as.character(treatment)=="N120","HN2024",default=NA_character_)]

trait_sets <- list(
  LN2023=c("dtf","height_cm","plants_m2","thousand_seed_weight_g",
           "protein_pct","fat_pct","panicle_length_cm","pedicel_length_cm"),
  LN2024=c("dtf","height_cm","plants_m2","number_of_tillers","days_to_harvest",
        "normalized_difference_vegetation_index","fluorescence","protein_pct"),
  HN2024=c("dtf","height_cm","plants_m2","number_of_tillers","days_to_harvest",
         "normalized_difference_vegetation_index","fluorescence","protein_pct")
)
trait_labels <- c(
  dtf="Days to flowering",height_cm="Plant height (cm)",
  plants_m2="Plant density (plants m−2)",number_of_tillers="Number of tillers",
  days_to_harvest="Days to harvest",
  normalized_difference_vegetation_index="Normalized Difference Vegetation Index",
  fluorescence="Fluorescence",thousand_seed_weight_g="Thousand-seed weight (g)",
  protein_pct="Seed protein concentration (%)",fat_pct="Seed fat concentration (%)",
  panicle_length_cm="Panicle length (cm)",pedicel_length_cm="Pedicel length (cm)"
)

get_component <- function(vc,pattern) {
  hit <- grep(pattern,rownames(vc),value=TRUE)
  if(!length(hit)) return(NA_real_)
  as.numeric(vc[hit[1],"component"])
}

fit_h2 <- function(env,trait) {
  z <- d[environment==env & is.finite(get(trait)),
         .(genotype,block,value=get(trait))]
  z <- droplevels(as.data.frame(z))
  if(nrow(z)<4L || nlevels(z$genotype)<2L) return(NULL)
  fit <- asreml(fixed=value~1,random=~genotype+block,
                residual=~idv(units),data=z,maxit=50,trace=FALSE)
  for(k in 1:5) {if(isTRUE(fit$converge)) break; fit <- update.asreml(fit)}
  vc <- summary(fit)$varcomp
  vg <- get_component(vc,"^genotype$")
  vb <- get_component(vc,"^block$")
  ve <- get_component(vc,"^units!units$|^units!R$|^units$")
  reps <- table(z$genotype)
  r_eff <- length(reps)/sum(1/as.numeric(reps))
  h2_entry <- if(is.finite(vg) && is.finite(ve) && vg+ve/r_eff>0)
    vg/(vg+ve/r_eff) else NA_real_
  h2_plot <- if(is.finite(vg) && is.finite(ve) && vg+ve>0) vg/(vg+ve) else NA_real_
  data.table(environment=env,trait=trait,trait_label=unname(trait_labels[trait]),
             n_observations=nrow(z),n_genotypes=nlevels(z$genotype),
             min_replication=min(reps),max_replication=max(reps),
             effective_replication=r_eff,genetic_variance=vg,
             block_variance=vb,residual_variance=ve,
             plot_level_H2=h2_plot,entry_mean_H2=h2_entry,
             converged=isTRUE(fit$converge),log_likelihood=fit$loglik)
}

ans <- list(); k <- 0L
for(env in names(trait_sets)) for(trait in trait_sets[[env]]) {
  k <- k+1L; message("Heritability ",k,"/24: ",env," / ",trait)
  ans[[k]] <- fit_h2(env,trait)
}
h2 <- rbindlist(ans,fill=TRUE)
h2[,environment_order:=match(environment,c("LN2023","LN2024","HN2024"))]
setorder(h2,environment_order,trait_label)
h2[,environment_order:=NULL]
fwrite(h2,file.path(resdir,"broad_sense_heritability_by_environment.csv"))

theme_pub <- theme_classic(base_size=12)+
  theme(text=element_text(family="sans"),plot.title=element_text(face="bold",size=16),
        axis.title=element_text(face="bold"),strip.background=element_rect(fill="#EAF2F7",colour=NA),
        strip.text=element_text(face="bold"))

h2plot <- copy(h2)
h2plot[,environment:=factor(environment,levels=c("LN2023","LN2024","HN2024"))]
ph <- ggplot(h2plot,aes(x=reorder(trait_label,entry_mean_H2),y=entry_mean_H2,fill=environment))+
  geom_col(width=.72,colour="#18354A",linewidth=.25)+coord_flip()+
  geom_text(aes(label=sprintf("%.2f",entry_mean_H2)),hjust=1.15,size=3.2,colour="white",fontface="bold")+
  facet_wrap(~environment,nrow=1,scales="free_y")+
  scale_fill_manual(values=c(LN2023="#2B6F9F",LN2024="#5AAE61",HN2024="#D95F02"),guide="none")+
  scale_y_continuous(limits=c(0,1.08),breaks=seq(0,1,.2),expand=c(0,0))+
  labs(x=NULL,y=expression("Entry-mean broad-sense heritability ("*H^2*")"),
       title="Broad-sense heritability within each field environment",
       subtitle="Genotype and block fitted as random effects; effective replication accounts for imbalance")+
  theme_pub
ggsave(file.path(figdir,"broad_sense_heritability_by_environment.png"),ph,width=13,height=6.7,dpi=600,bg="white")
ggsave(file.path(figdir,"broad_sense_heritability_by_environment.pdf"),ph,width=13,height=6.7)

# Individual environment bar plots.
for(env in c("LN2023","LN2024","HN2024")) {
  p <- ggplot(h2[environment==env],aes(reorder(trait_label,entry_mean_H2),entry_mean_H2))+
    geom_col(width=.7,fill=c(LN2023="#2B6F9F",LN2024="#5AAE61",HN2024="#D95F02")[[env]],
             colour="#18354A",linewidth=.25)+coord_flip()+
    geom_text(aes(label=sprintf("%.2f",entry_mean_H2)),hjust=1.15,size=3.5,colour="white",fontface="bold")+
    scale_y_continuous(limits=c(0,1.08),breaks=seq(0,1,.2),expand=c(0,0))+
    labs(x=NULL,y=expression("Entry-mean "*H^2),title=paste("Broad-sense heritability:",env))+theme_pub
  ggsave(file.path(figdir,paste0("broad_sense_heritability_",env,".png")),p,width=8,height=5.5,dpi=600,bg="white")
  ggsave(file.path(figdir,paste0("broad_sense_heritability_",env,".pdf")),p,width=8,height=5.5)
}

# Long plot-level phenotypes for distribution plots.
long <- rbindlist(lapply(names(trait_sets),function(env)
  rbindlist(lapply(trait_sets[[env]],function(trait) {
    z <- d[environment==env & is.finite(get(trait)),.(environment,genotype,block,value=get(trait))]
    z[,`:=`(trait=trait,trait_label=unname(trait_labels[trait]))]; z
  }))),fill=TRUE)
fwrite(long,file.path(resdir,"phenotypes_long_by_environment.csv"))

box_cols <- c(`1`="#F8766D",`2`="#00BFC4",`3`="#C77CFF")
for(env in c("LN2023","LN2024","HN2024")) {
  z <- copy(long[environment==env]); z[,block_label:=paste("Block",block)]
  p <- ggplot(z,aes(x=block_label,y=value,fill=block_label))+
    geom_boxplot(width=.62,colour="#222222",linewidth=.45,outlier.size=1.15)+
    facet_wrap(~trait_label,scales="free_y",ncol=4)+
    scale_fill_manual(values=setNames(unname(box_cols),paste("Block",names(box_cols))),guide="none")+
    labs(x=NULL,y="Phenotypic distribution",title=paste("Phenotype distributions:",env),
         subtitle="Raw field-plot observations grouped by block; boxes show median and interquartile range")+
    theme_bw(base_size=12)+theme(plot.title=element_text(face="bold",size=16),
      axis.title.y=element_text(face="bold"),strip.background=element_rect(fill="#D9D9D9",colour="#333333"),
      strip.text=element_text(size=10,face="bold",colour="#163B9A"),
      axis.text.x=element_text(angle=90,vjust=.5,hjust=1),panel.grid.minor=element_blank())
  ggsave(file.path(figdir,paste0("phenotype_boxplots_",env,".png")),p,width=12,height=6.8,dpi=600,bg="white")
  ggsave(file.path(figdir,paste0("phenotype_boxplots_",env,".pdf")),p,width=12,height=6.8)
}

long24 <- copy(long[environment %in% c("LN2024","HN2024")])
long24[,environment:=factor(environment,levels=c("LN2024","HN2024"))]
p24 <- ggplot(long24,aes(environment,value,fill=environment))+
  geom_boxplot(width=.58,outlier.shape=NA,alpha=.82,linewidth=.4)+
  geom_jitter(aes(colour=environment),width=.14,height=0,size=.45,alpha=.2)+
  facet_wrap(~trait_label,scales="free_y",ncol=4)+
  scale_fill_manual(values=c(LN2024="#5AAE61",HN2024="#D95F02"),guide="none")+
  scale_colour_manual(values=c(LN2024="#238B45",HN2024="#A63603"),guide="none")+
  labs(x=NULL,y="Plot-level phenotype",title="Phenotype distributions in LN2024 and HN2024",
       subtitle="Descriptive comparison only; nitrogen treatments occupied separate field halves")+
  theme_pub+theme(strip.text=element_text(size=9))
ggsave(file.path(figdir,"phenotype_boxplots_LN2024_vs_HN2024.png"),p24,width=12,height=6.8,dpi=600,bg="white")
ggsave(file.path(figdir,"phenotype_boxplots_LN2024_vs_HN2024.pdf"),p24,width=12,height=6.8)

message("Saved heritability results to ",resdir," and figures to ",figdir)
