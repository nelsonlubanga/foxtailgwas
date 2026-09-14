#!/usr/bin/env Rscript
# CIGAR-aware lift-over to Yugu1 T2T and independent T2T gene annotation in R.
suppressPackageStartupMessages(library(data.table))
root<-normalizePath("."); base<-file.path(root,"results/gwas/candidate_genes_r")
out<-file.path(base,"reference_comparison"); dir.create(out,recursive=TRUE,showWarnings=FALSE)
ref<-file.path(root,"data/reference"); t2t<-file.path(ref,"Yugu1_T2T_v1.0")

report<-fread(file.path(ref,"GCF_000263155.2_Setaria_italica_v2.0_assembly_report.txt"),sep="\t",header=FALSE,comment.char="#",fill=TRUE)
scaffold_refseq<-setNames(report[[7]],toupper(report[[1]]))
paf<-fread(file.path(root,"data/processed/reference_alignment/Yugu1_v2_to_T2T.paf"),sep="\t",header=FALSE,fill=TRUE)
setnames(paf,1:12,c("qname","qlen","qstart","qend","strand","tname","tlen","tstart","tend","matches","block","mapq"))
paf[,cigar:=sub("^cg:Z:","",apply(.SD,1,function(x){z<-x[grepl("^cg:Z:",x)];if(length(z))z[1] else NA_character_})),.SDcols=13:ncol(paf)]
paf<-paf[!is.na(cigar)]; setorder(paf,qname,qstart,qend)

map_cigar<-function(a,q0){
  tok<-regmatches(a$cigar,gregexpr("[0-9]+[MIDNSHP=X]",a$cigar))[[1]]; q<-if(a$strand=="+")a$qstart else a$qend-1; tt<-a$tstart
  for(v in tok){n<-as.integer(sub("[A-Z=].*$","",v));op<-sub("^[0-9]+","",v);cq<-op%chin%c("M","I","=","S","X");ct<-op%chin%c("M","D","N","=","X")
    if(cq){inside<-if(a$strand=="+") q<=q0&&q0<q+n else q-n<q0&&q0<=q; off<-if(a$strand=="+")q0-q else q-q0;if(inside)return(if(ct)tt+off else NA_real_);q<-q+if(a$strand=="+")n else -n};if(ct)tt<-tt+n }
  NA_real_
}
cache<-new.env(hash=TRUE)
lift<-function(scaffold,pos){key<-paste(scaffold,pos);if(exists(key,cache,inherits=FALSE))return(get(key,cache));qn<-scaffold_refseq[[scaffold]];q0<-pos-1
  aa<-paf[qname==qn & qstart<=q0 & qend>q0];if(!nrow(aa)){z<-list(status="unmapped");assign(key,z,cache);return(z)}
  mm<-lapply(seq_len(nrow(aa)),function(i)cbind(aa[i],t0=map_cigar(aa[i],q0)));mm<-rbindlist(mm);mm<-mm[!is.na(t0)]
  if(!nrow(mm)){z<-list(status="unmapped");assign(key,z,cache);return(z)};setorder(mm,-mapq,-matches,block);amb<-uniqueN(mm[,.(tname,t0)])>1; a<-mm[1]
  z<-list(status=if(amb)"ambiguous" else "unique",t2t_chr=a$tname,t2t_pos=a$t0+1,strand=a$strand,mapq=a$mapq,alignment_identity=a$matches/a$block,candidate_mappings=nrow(mm));assign(key,z,cache);z}

ann<-fread(cmd=paste("gzip -dc",shQuote(file.path(t2t,"Yugu1_T2T_func_v1.0.txt.gz"))),sep="\t",fill=TRUE)
gff<-fread(cmd=paste("gzip -dc",shQuote(file.path(t2t,"Yugu1_T2T_v1.0.gff3.gz")),"| awk 'substr($0,1,1) != \"#\"'"),sep="\t",header=FALSE,quote="",fill=TRUE)
attr<-function(x,key){m<-regexpr(paste0("(?:^|;)",key,"=[^;]*"),x,perl=TRUE);z<-rep(NA_character_,length(x));ok<-m>0;z[ok]<-regmatches(x,m);sub(paste0("^;?",key,"="),"",z)}
genes<-gff[V3=="gene",.(lift_t2t_chr=V1,t2t_gene_start=as.integer(V4),t2t_gene_end=as.integer(V5),t2t_strand=V7,t2t_gene_id=attr(V9,"ID"))]
pick<-function(n)if(n%chin%names(ann))n else NA_character_
setnames(ann,"GeneID","t2t_gene_id"); keep<-intersect(c("t2t_gene_id","Symbol","Description","Pathway","GO Function","GO Process"),names(ann));genes<-merge(genes,ann[,..keep],by="t2t_gene_id",all.x=TRUE)
setnames(genes,intersect(names(genes),c("Symbol","Description","Pathway","GO Function","GO Process")),c("symbol","description","pathway","go_function","go_process")[match(intersect(names(genes),c("Symbol","Description","Pathway","GO Function","GO Process")),c("Symbol","Description","Pathway","GO Function","GO Process"))])
setorder(genes,lift_t2t_chr,t2t_gene_start)

hits<-fread(file.path(base,"significant_snps_ld_intervals.csv"));markers<-fread(file.path(root,"data/processed/genotypes/Fox_geno.qc.012.pos"),header=FALSE,col.names=c("scaffold","position"))
lifted<-vector("list",nrow(hits));cand<-list()
for(i in seq_len(nrow(hits))){h<-hits[i];sc<-paste0("SCAFFOLD_",as.integer(h$Chr));le<-lift(sc,h$Pos);z<-c(as.list(h),setNames(le,paste0("lift_",names(le))))
 if(le$status%chin%c("unique","ambiguous")){local<-markers[scaffold==sc&position>=h$ld_start&position<=h$ld_end];mp<-unlist(lapply(local$position,function(p){q<-lift(sc,p);if(identical(q$status,"unique")&&identical(q$t2t_chr,le$t2t_chr))q$t2t_pos else NULL}));mp<-c(mp,le$t2t_pos);st<-min(mp);en<-max(mp);z$t2t_interval_start<-st;z$t2t_interval_end<-en;z$interval_markers_lifted<-length(mp);z$interval_mapping_fraction<-length(mp)/max(nrow(local),1)
   gg<-genes[lift_t2t_chr==le$t2t_chr&t2t_gene_end>=st&t2t_gene_start<=en];rel<-"lifted_LD_interval";if(!nrow(gg)){allg<-genes[lift_t2t_chr==le$t2t_chr];d<-pmax(allg$t2t_gene_start-le$t2t_pos,le$t2t_pos-allg$t2t_gene_end,0);gg<-allg[which.min(d)];rel<-"nearest_gene"};gg[,gene_relation:=ifelse(t2t_gene_start<=le$t2t_pos&t2t_gene_end>=le$t2t_pos,"contains_lifted_lead_snp",rel)];gg[,distance_to_lifted_lead_bp:=pmax(t2t_gene_start-le$t2t_pos,le$t2t_pos-t2t_gene_end,0)];cand[[i]]<-cbind(as.data.table(z)[rep(1,nrow(gg))],gg)};lifted[[i]]<-as.data.table(z);if(i%%20==0)message("Lifted ",i,"/",nrow(hits))}
lifted<-rbindlist(lifted,fill=TRUE);cand<-rbindlist(cand,fill=TRUE);fwrite(lifted,file.path(out,"t2t_significant_snps_lifted.csv"));fwrite(cand,file.path(out,"t2t_candidate_genes_all.csv"))
ranked<-cand[,.(association_count=.N,unique_lead_snps=uniqueN(SNP),datasets=paste(sort(unique(dataset)),collapse=";"),traits=paste(sort(unique(trait)),collapse=";"),models=paste(sort(unique(model)),collapse=";"),minimum_p=min(P.value),maf05_associations=sum(trait_specific_maf_pass),lead_snps_inside_gene=sum(gene_relation=="contains_lifted_lead_snp"),minimum_distance_to_lead_bp=min(distance_to_lifted_lead_bp)),by=.(t2t_gene_id,symbol,description,lift_t2t_chr,t2t_gene_start,t2t_gene_end)]
ranked[,evidence_score:=pmin(lengths(strsplit(models,";",fixed=TRUE)),3)+2*pmin(lengths(strsplit(datasets,";",fixed=TRUE)),2)+2*(lead_snps_inside_gene>0)+(maf05_associations>0)];setorder(ranked,-evidence_score,-unique_lead_snps,minimum_p);fwrite(ranked,file.path(out,"t2t_candidate_genes_ranked.csv"));fwrite(cand[trait_specific_maf_pass==TRUE&gene_relation=="contains_lifted_lead_snp"][order(P.value)],file.path(out,"t2t_lead_snp_inside_gene_maf05.csv"))
old<-fread(file.path(base,"candidate_genes_all.csv"))[,.(old_candidate_genes=paste(sort(unique(gene_id)),collapse=";"),old_candidate_gene_count=uniqueN(gene_id)),by=.(dataset,trait,model,SNP)]
tt<-cand[,.(t2t_candidate_genes=paste(sort(unique(t2t_gene_id)),collapse=";"),t2t_candidate_gene_count=uniqueN(t2t_gene_id)),by=.(dataset,trait,model,SNP)]
fwrite(merge(merge(lifted,old,by=c("dataset","trait","model","SNP"),all.x=TRUE),tt,by=c("dataset","trait","model","SNP"),all.x=TRUE),file.path(out,"candidate_gene_reference_comparison.csv"))
message(paste(capture.output(print(lifted[,.N,by=lift_status])),collapse="\n"));message("R T2T analysis: ",nrow(cand)," links; ",uniqueN(cand$t2t_gene_id)," unique genes.")
