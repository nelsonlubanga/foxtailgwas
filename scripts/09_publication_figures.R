#!/usr/bin/env Rscript
# Publication Manhattan, QQ, SNP-effect and regional-association figures in R.
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(patchwork);library(scales)})
set.seed(20260907)
root<-normalizePath(".");gwas<-file.path(root,"results/gwas");cg<-file.path(gwas,"candidate_genes_r")
fig<-file.path(root,"figures/publication_r_final");dirs<-file.path(fig,c("manhattan","qq","snp_effects","regional"));invisible(lapply(dirs,dir.create,recursive=TRUE,showWarnings=FALSE))
n_markers<-nrow(fread(file.path(root,"data/processed/genotypes/Fox_geno.qc.012.pos"),header=FALSE));bonf<-0.05/n_markers
labels<-c(dtf="Days to flowering",height_cm="Plant height (cm)",plants_m2="Plant density (plants m−2)",thousand_seed_weight_g="Thousand-seed weight (g)",protein_pct="Seed protein concentration (%)",fat_pct="Seed fat concentration (%)",panicle_length_cm="Panicle length (cm)",pedicel_length_cm="Pedicel length (cm)",number_of_tillers="Number of tillers",days_to_harvest="Days to harvest",normalized_difference_vegetation_index="Normalized Difference Vegetation Index",fluorescence="Fluorescence")
pretty_trait<-function(x)if(x%chin%names(labels))unname(labels[x]) else gsub("_"," ",x)
pretty_env<-function(x)unname(c(`2023`="LN2023",`2024_N40`="LN2024",`2024_N120`="HN2024")[x])
safe<-function(x)gsub("[^A-Za-z0-9_.-]+","_",x)
theme_pub<-theme_classic(base_size=10)+theme(plot.title=element_text(face="bold",size=10),axis.title=element_text(face="bold"),legend.position="right")
save_plot<-function(p,stem,w=7,h=5){ggsave(paste0(stem,".pdf"),p,width=w,height=h,device=cairo_pdf);ggsave(paste0(stem,".png"),p,width=w,height=h,dpi=300,bg="white")}
save_gwas_plot<-function(p,stem,w,h)ggsave(paste0(stem,".png"),p,width=w,height=h,dpi=300,bg="white")

status<-unique(fread(file.path(gwas,"batch_status.csv"))[status %chin% c("completed","completed_recovered"),.(dataset,trait,model,n)])
manifest<-list()
for(i in seq_len(nrow(status))){a<-status[i];dd<-file.path(gwas,a$dataset,a$trait,a$model);ff<-list.files(dd,pattern="GWAS_Results.*NYC.*csv$",full.names=TRUE)
 if(!length(ff)){warning("Missing association table: ",dd);next};d<-fread(ff[1],select=c("SNP","Chr","Pos","P.value","MAF"));d<-d[is.finite(P.value)&P.value>0&is.finite(Pos)]
 # Global VCF MAF was 0.05; low-MAF variants arising only in the trait subset are omitted from final figures.
 before<-nrow(d);d<-d[is.na(MAF)|MAF>=.05];d[,ChrLabel:=ifelse(Chr%between%c(1,9),as.character(Chr),"Unplaced")]
 ord<-c(as.character(1:9),"Unplaced");d[,ChrLabel:=factor(ChrLabel,levels=ord)];lens<-d[,.(mx=max(Pos)),by=ChrLabel][order(ChrLabel)];lens[,offset:=shift(cumsum(mx),fill=0)];d<-merge(d,lens[,.(ChrLabel,offset)],by="ChrLabel");d[,cumpos:=Pos+offset]
 ticks<-d[,.(tick=(min(cumpos)+max(cumpos))/2),by=ChrLabel];d[,mlogp:=-log10(pmax(P.value,.Machine$double.xmin))]
 ttl<-paste(pretty_env(a$dataset),pretty_trait(a$trait),a$model,sep=" · ")
 sig<-d[P.value<=bonf]
 sig_subtitle<-if(nrow(sig)>0)paste0(nrow(sig)," Bonferroni-significant SNP",ifelse(nrow(sig)==1,"","s")) else NULL
 pm<-ggplot(d,aes(cumpos,mlogp,color=ChrLabel))+geom_point(size=.28,alpha=.68)+geom_hline(yintercept=-log10(bonf),linetype=2,color="#B2182B",linewidth=.55)+geom_point(data=sig,aes(cumpos,mlogp),inherit.aes=FALSE,shape=21,size=2.15,stroke=.45,fill="#D73027",color="black",alpha=.98)+scale_color_manual(values=rep(c("#2166AC","#67A9CF"),length.out=length(ord)),guide="none",drop=FALSE)+scale_x_continuous(breaks=ticks$tick,labels=ifelse(as.character(ticks$ChrLabel)=="Unplaced","Unpl.",as.character(ticks$ChrLabel)),expand=expansion(mult=c(.005,.02)))+labs(x="Chromosome",y=expression(-log[10](italic(P))),title=ttl,subtitle=sig_subtitle)+theme_pub+theme(plot.subtitle=element_text(size=8,color="#4D4D4D"))
 stem<-file.path(dirs[1],safe(paste(a$dataset,a$trait,a$model,sep="_")));save_gwas_plot(pm,stem,8.2,4.4)
 obs<-sort(d$P.value);nn<-length(obs);qq<-data.table(expected=-log10(ppoints(nn)),observed=-log10(obs));lambda<-median(qchisq(1-obs,1),na.rm=TRUE)/qchisq(.5,1)
 pq<-ggplot(qq,aes(expected,observed))+geom_abline(slope=1,intercept=0,color="#B2182B",linetype=2,linewidth=.5)+geom_point(size=.35,alpha=.65,color="#2166AC")+coord_equal()+labs(x=expression(Expected~~-log[10](italic(P))),y=expression(Observed~~-log[10](italic(P))),title=ttl,subtitle=sprintf("Genomic inflation factor λ = %.3f",lambda))+theme_pub
 save_gwas_plot(pq,file.path(dirs[2],safe(paste(a$dataset,a$trait,a$model,sep="_"))),4.8,4.8)
 manifest[[i]]<-data.table(dataset=a$dataset,trait=a$trait,model=a$model,input=ff[1],markers_in_table=before,markers_plotted=nn,significant_snps_highlighted=nrow(sig),trait_subset_maf_filter=.05,bonferroni_threshold=bonf,lambda_gc=lambda)
 if(i%%6==0)message("Manhattan/QQ: ",i,"/",nrow(status))
}
fwrite(rbindlist(manifest,fill=TRUE),file.path(fig,"gwas_figure_manifest.csv"))

# Load compact signed-byte genotypes for SNP-effect and regional plots.
gd<-file.path(root,"data/processed/genotypes");samples<-fread(file.path(gd,"Fox_geno.qc.012.indv"),header=FALSE)[[1]];mk<-fread(file.path(gd,"Fox_geno.qc.012.pos"),header=FALSE,col.names=c("scaffold","Pos"));mk[,SNP:=paste(scaffold,Pos,sep="_")];mi<-setNames(seq_len(nrow(mk)),mk$SNP)
con<-file(file.path(gd,"Fox_geno.qc.int8.bin"),"rb");rr<-readBin(con,"raw",n=length(samples)*nrow(mk));close(con);G<-matrix(rr,nrow=length(samples),byrow=TRUE,dimnames=list(samples,NULL))
pf<-c(`2023`="gwas_phenotypes_2023.csv",`2024_N40`="gwas_phenotypes_2024_N40.csv",`2024_N120`="gwas_phenotypes_2024_N120.csv");phen<-lapply(pf,function(x){z<-fread(file.path(root,"data/processed/blues",x));setnames(z,1,"genotype");z})

direct<-fread(file.path(cg,"candidate_genes_lead_snp_inside_gene_maf05.csv"))[order(P.value)];direct<-unique(direct,by=c("dataset","trait","SNP"));summ<-list()
for(i in seq_len(nrow(direct))){h<-direct[i];p<-phen[[h$dataset]][!is.na(get(h$trait))&genotype%chin%samples,.(genotype,value=get(h$trait))];rows<-match(p$genotype,samples);p[,dosage:=as.integer(G[cbind(rows,mi[[h$SNP]])])];p[dosage==255L,dosage:=NA_integer_];p<-p[!is.na(dosage)];ss<-p[,.(n=.N,mean=mean(value),sd=sd(value),median=median(value)),by=dosage];ss[,`:=`(dataset=h$dataset,trait=h$trait,SNP=h$SNP,gene_id=h$gene_id)];summ[[i]]<-ss
 pp<-ggplot(p,aes(factor(dosage),value))+geom_boxplot(width=.58,outlier.shape=NA,fill="#D9EAF4",color="#1B4F72",linewidth=.7)+geom_jitter(width=.10,height=0,size=2.15,alpha=.78,shape=21,fill="#3C8DBC",color="white",stroke=.25)+stat_summary(fun=mean,geom="point",shape=23,size=3.7,fill="#D73027",color="black",stroke=.55)+scale_x_discrete(labels=function(x){vapply(x,function(q)sprintf("%s\n(n=%d)",q,p[dosage==as.integer(q),.N]),"")})+labs(x="Alternate-allele dosage",y=pretty_trait(h$trait),title=paste(pretty_env(h$dataset),h$SNP,sep=" · "),subtitle=paste0(h$gene_id," · GWAS P = ",format(h$P.value,digits=2,scientific=TRUE)," · MAF = ",sprintf("%.3f",h$MAF)))+theme_pub
 save_plot(pp,file.path(dirs[3],safe(paste(h$dataset,h$trait,h$SNP,h$gene_id,sep="_"))),5.4,4.5)
}
fwrite(rbindlist(summ,fill=TRUE),file.path(cg,"lead_snp_genotype_effect_summary_r.csv"));message("SNP-effect plots: ",nrow(direct))

# Regional plots for the eight strongest recurrent MAF>=0.05 loci.
hits<-fread(file.path(gwas,"summary/bonferroni_significant_associations.csv"))[MAF>=.05];hits[,recurrence:=.N,by=SNP];reps<-unique(hits[recurrence>=2][order(P.value)],by="SNP")[1:min(8,.N)];genes<-fread(file.path(cg,"candidate_genes_all.csv"));rman<-list()
for(i in seq_len(nrow(reps))){h<-reps[i];ff<-list.files(file.path(gwas,h$dataset,h$trait,h$model),pattern="GWAS_Results.*NYC.*csv$",full.names=TRUE)[1];d<-fread(ff,select=c("SNP","Chr","Pos","P.value","MAF"));d<-d[Chr==h$Chr&Pos>=h$Pos-250000&Pos<=h$Pos+250000&(is.na(MAF)|MAF>=.05)];p<-phen[[h$dataset]];rows<-match(p[!is.na(get(h$trait))&genotype%chin%samples,genotype],samples);idx<-unname(mi[d$SNP]);x<-matrix(as.integer(G[rows,idx,drop=FALSE]),nrow=length(rows));x[x==255L]<-NA;cm<-colMeans(x,na.rm=TRUE);mm<-which(is.na(x),arr.ind=TRUE);if(nrow(mm))x[mm]<-cm[mm[,2]];x<-sweep(x,2,colMeans(x),"-");li<-match(h$SNP,d$SNP);lead<-x[,li];den<-sqrt(sum(lead^2)*colSums(x^2));d[,r2:=(as.numeric(crossprod(lead,x))/den)^2];d[!is.finite(r2),r2:=0]
 top<-ggplot(d,aes(Pos/1e6,-log10(P.value),color=r2))+geom_point(size=2.0,alpha=.85)+geom_point(data=d[SNP==h$SNP],shape=23,size=4.5,stroke=.7,fill="#D73027",color="black")+geom_hline(yintercept=-log10(bonf),linetype=2,color="#B2182B",linewidth=.55)+scale_color_viridis_c(limits=c(0,1),name=expression(LD~~r^2))+labs(x=NULL,y=expression(-log[10](italic(P))),title=paste(pretty_env(h$dataset),pretty_trait(h$trait),h$model,sep=" · "))+theme_pub
 gg<-unique(genes[dataset==h$dataset&trait==h$trait&SNP==h$SNP],by="gene_id");if(!nrow(gg))gg<-genes[0];gg[,level:=(seq_len(.N)-1)%%3]
 bot<-ggplot(gg)+geom_segment(aes(x=gene_start/1e6,xend=gene_end/1e6,y=level,yend=level),linewidth=2.5,color="#2166AC")+geom_text(data=gg[gene_start<=h$Pos&gene_end>=h$Pos],aes(x=(gene_start+gene_end)/2e6,y=level+.25,label=gene_symbol),size=2.4)+coord_cartesian(xlim=range(d$Pos)/1e6,ylim=c(-.4,3))+labs(x=paste0("Scaffold ",h$Chr," position (Mb)"),y="Genes")+theme_pub+theme(axis.text.y=element_blank(),axis.ticks.y=element_blank())
 pp<-top/bot+plot_layout(heights=c(4,1.25));stem<-file.path(dirs[4],safe(paste(h$dataset,h$trait,h$model,h$SNP,sep="_")));save_plot(pp,stem,8.2,5.6);rman[[i]]<-cbind(h,regional_markers=nrow(d),candidate_genes_shown=nrow(gg),plot=paste0(basename(stem),".pdf"))
}
fwrite(rbindlist(rman,fill=TRUE),file.path(cg,"regional_plot_manifest_r.csv"));message("Regional plots: ",nrow(reps),". All R figures saved in ",fig)
