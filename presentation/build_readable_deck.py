from pathlib import Path
# Reuse the presentation styling and drawing helpers only.
base=Path(__file__).resolve().parent
exec((base/'build_presentation.py').read_text().split('# 1\n')[0])
from pptx.enum.text import MSO_ANCHOR
# Generous spacing and larger body text for projection.
def points(s,items):
 for i,(head,body) in enumerate(items):
  y=1.95+i*1.45
  txt(s,head,.75,y,11.8,.48,25,GREEN,True)
  txt(s,body,.75,y+.53,11.8,.78,23)
def two(s,left,right):
 for x,(head,body) in zip([.75,6.85],[left,right]):
  box(s,x,2,5.7,3.85,WHITE);txt(s,head,x+.25,2.22,5.2,.7,27,GREEN,True);txt(s,body,x+.25,3.12,5.2,2.45,24)
def new(title,section,notes='',source='Lubanga et al. · supplied manuscript'):
 return slide(title,kicker=section,notes=notes,source=source)
def figure(title,name,take,source):
 s=new(title,'RESULTS',source=source);pic(s,name,.65,1.95,12,3.95);call(s,take);return s
def table(s,rows,widths=None):
 t=s.shapes.add_table(len(rows),len(rows[0]), Inches(.75),Inches(2),Inches(11.85),Inches(3.8)).table
 if widths:
  for col,w in zip(t.columns,widths):col.width=Inches(w)
 for i,row in enumerate(rows):
  for j,v in enumerate(row):
   c=t.cell(i,j);c.text=str(v);c.fill.solid();c.fill.fore_color.rgb=RGBColor.from_string(INK if i==0 else ('FFFFFF' if i%2 else 'E8EEE8'));c.vertical_anchor=MSO_ANCHOR.MIDDLE
   for p in c.text_frame.paragraphs:p.font.name='Aptos';p.font.size=Pt(23);p.font.color.rgb=RGBColor.from_string(WHITE if i==0 else INK)
 return t
s=new('Sparse testing and multi-environment\ngenomic prediction in Miscanthus','',notes='Opening. Frame the talk around allocating phenotyping effort and judging within-group selection value.')
txt(s,'Designing trials within a fixed phenotyping budget',.75,3,11.8,.8,28,GREEN)
txt(s,'Nelson Lubanga, Iain Donnison, Chris Davey, Beatrice Ifie,\nGancho Slavov, Kerrie Farrar and Diego Jarquin',.75,4.35,11.8,1,23)
txt(s,'Aberystwyth University • Oregon State University • University of Florida',.75,5.8,11.8,.6,18,MUTED)
s=new('Breeding Miscanthus takes time and resources','BACKGROUND');points(s,[('A perennial crop','Mature biomass performance takes several years to assess.'),('Genotype × environment interaction','Candidate rankings can change across sites and years.'),('A phenotyping constraint','Multi-environment measurements compete for a fixed budget.')])
s=new('Sparse testing predicts missing observations','BACKGROUND',notes='OL candidates may be observed in all environments; NOL candidates are observed once in these designs. Genomic relationships help connect different candidates. Sparse testing does not require every genotype to have missing records.')
two(s,('Overlapping genotypes (OL)','Measured across all five environments in this study.'),('Non-overlapping genotypes (NOL)','Measured in one environment; missing combinations are predicted.'));call(s,'The aim: cover more unique candidates within the same measurement budget.')
s=new('Three questions for a breeding programme','OBJECTIVES');points(s,[('Models','Does genomic × environment modelling improve prediction?'),('Trial allocation','How do overlap and unique genotype coverage affect prediction?'),('Selection','Can predictions rank candidates within population groups?')])
s=new('Plant material: 125 genotypes','MATERIALS · POPULATION',notes='These are three population groups, corresponding to two species and interspecific hybrids. The hybrid group is particularly small.');two(s,('Two species','56 M. sacchariflorus\n\n47 M. sinensis'),('Interspecific hybrids','22 genotypes\n\nThree population groups in total'))
s=new('Two sites, five site-year environments','MATERIALS · FIELD TRIALS',notes='Not all genotype by environment observations are available. Because Miscanthus is perennial, the same plants are measured in successive years at a site.');two(s,('Aberystwyth, UK','2015\n2016'),('Braunschweig, Germany','2014\n2015\n2016'));call(s,'An environment is a site × year combination; plants recur across years.')
s=new('Three traits and genome-wide markers','MATERIALS · MEASUREMENTS',notes='DM is dry matter yield; FW is fresh weight; MC is moisture content. RAD-seq and UNEAK produced the source marker dataset. After QC 13,687 SNPs remained; 11,901 contributed to the prediction relationship matrix because of input coding. A correctly coded 13,687-marker matrix gave off-diagonal r=0.999 and changed predictive ability by at most 0.033. Ploidy-specific dosage was unavailable.');two(s,('Phenotypes','Dry matter yield (DM)\n\nFresh weight (FW)\n\nMoisture content (MC)'),('Markers','RAD-seq / UNEAK\n\n13,687 SNPs after QC\n11,901 in prediction matrix'));call(s,'Matrix sensitivity: off-diagonal r = 0.999; predictive ability changed by ≤0.033.')
s=new('From field measurements to prediction','METHODS · ANALYSIS',notes='Stage one uses site-specific mixed models to obtain genotype BLUEs. Population group and genotype nested within group are fixed; design effects are random. Stage two uses BGLR with the three genomic prediction models. Population group is fixed in the main prediction analyses.');points(s,[('1 · Adjust field measurements','Estimate genotype BLUEs within each environment.'),('2 · Fit prediction models','Use environment, population group, genotype and genomic effects.'),('3 · Evaluate held-out observations','Predictive ability = correlation between predictions and BLUEs.')])
s=new('What do genomic effects and G×E add?','METHODS · MODELS',notes='M1 has a non-marker genotype effect; M2 adds a genomic effect using the relationship matrix; M3 adds genomic by environment covariance, constructed with a Hadamard product. Population group is fixed in the main prediction analysis, but random for the variance-component illustration.');table(s,[['Model','Components added'],['M1','Environment + population group + genotype'],['M2','M1 + genomic main effect'],['M3','M2 + genomic × environment interaction']],[1.5,10.35]);call(s,'Compare genomic models with a baseline that uses no marker information.')
s=new('CV1 and CV2 represent different decisions','METHODS · VALIDATION',notes='Five-fold cross-validation is used. CV1 masks the whole genotype across environments. CV2 retains records of the target genotype elsewhere. Site-year CV2 can use another year of the same plants at the same site, so it does not establish prediction in a new environment.');two(s,('CV1 · Untested candidate','Mask every observation of the genotype.\n\nCan genomic relationships support prediction?'),('CV2 · Partly tested candidate','Retain observations in other environments.\n\nCan existing records fill measurement gaps?'));call(s,'Site-year CV2 may use records from another year at the same site.')
s=new('Six sparse designs share the same budget','METHODS · SPARSE TESTING',source='Manuscript · Table 1',notes='Each design has 25 measurements per environment and 125 in total. OL genotypes are measured in all five environments and NOL genotypes once. Each design was independently replicated ten times. Increasing OL simultaneously reduces unique training genotypes; the series cannot identify a universal optimum overlap fraction.');table(s,[['Design','NOL / environment','OL / environment','Unique genotypes'],['D1','25','0','125'],['D2','20','5','105'],['D3','15','10','85'],['D4','10','15','65'],['D5','5','20','45'],['D6','0','25','25']],[1.5,3.7,3.6,3.05]);call(s,'125 measurements in every design; unique genotype coverage changes from 125 to 25.')
s=new('Evaluate ranking within population groups','METHODS · WITHIN-GROUP VALIDATION',notes='Combine years into one BLUE per genotype per site. In each partition subtract trial by population-group means estimated from training data only; add the training means back to predictions. At evaluation centre both predicted and observed values by group to calculate the pooled within-group correlation. This is not an average of three group-specific correlations. Five folds and ten repetitions use identical partitions. Trial-level CV2 uses the other site, removing the same-site repeated-year information.');points(s,[('One record per genotype per site','Combine years before cross-validation.'),('Adjustment uses training data only','Remove trial × group means; add them back to predictions.'),('Evaluate within-group differences','Centre predictions and BLUEs by group before correlating.')]);call(s,'Trial-level CV2 uses the other site; five folds × 10 repetitions.')
s=new('The three population groups are distinct','RESULTS · POPULATION STRUCTURE',source='Manuscript · Figure 1a');pic(s,'pca_panel.png',.75,1.85,8,4.95);txt(s,'PC1 explains\n22.57%\n\nHybrids lie between the parental species.',9,2.3,3.5,3.5,25)
s=new('Population groups also differ in phenotype','RESULTS · PHENOTYPES',source='Manuscript · Figure 1b',notes='Group differences are significant at P≤0.003 in 14 of 15 trait by environment combinations. Hybrids have the highest DM and FW in every environment; M. sacchariflorus has the lowest median moisture content.');pic(s,'phenotypes_panel.png',.75,1.85,8.3,4.95);txt(s,'Hybrids:\nhighest DM and FW\n\nM. sacchariflorus:\nlowest median MC',9.3,2.3,3.3,3.6,24)
s=new('G×E accounts for meaningful variation','RESULTS · VARIANCE COMPONENTS',source='Manuscript · Figure 2',notes='Population group was random here so that its variance could be estimated. Under M3, genomic by environment interaction accounts for 13.2% for DM, 16.9% for FW and 14.5% for MC. Residual variance reductions relative to M1 are 50%, 59% and 45%, respectively; these are model variance comparisons, not prediction gains.');pic(s,'image2.png',.65,1.95,9.1,4.7);txt(s,'G×E in M3\n\nDM  13.2%\nFW  16.9%\nMC  14.5%',10,2.3,2.65,3.6,24)
figure('CV1: predicting completely untested genotypes','image3.png','M3 generally helps DM and FW; performance varies across environments.','Manuscript · Figure 3a')
figure('CV2: existing phenotypes improve prediction','image4.png','Prediction is generally stronger when the genotype has observations elsewhere.','Manuscript · Figure 3b')
figure('Broader genotype coverage supports prediction','image5.png','M3 is best for DM/FW across these sparse designs; MC shows no consistent M3 gain.','Manuscript · Figure 4')
s=new('Separate coverage from overlap','RESULTS · DESIGN SENSITIVITY',source='Manuscript · Table S3',notes='The fixed-unique-genotype analyses keep 40, 36 or 32 genotypes within two-, three- or four-environment subsets. Overlap changes, but total measurements also change. These sensitivity analyses support an important role for genotype coverage; they do not provide a fully controlled causal estimate or a universal overlap optimum.');table(s,[['Environments','Unique genotypes','Predictive ability'],['2','40','0.43–0.44'],['3','36','0.41–0.43'],['4','32','0.38–0.44']],[3.25,3.9,4.7]);call(s,'Holding genotype number fixed gives relatively small changes as overlap varies.')
for scheme,rows,title,take in [
 ('CV1',[['DM','0.52 / 0.54','0.08 / 0.22'],['FW','0.50 / 0.53','0.15 / 0.27'],['MC','0.51 / 0.53','0.24 / 0.27']],'Untested candidates are hard to rank within groups','Group differences contribute strongly to across-panel CV1 predictive ability.'),
 ('CV2',[['DM','0.68 / 0.65','0.41 / 0.46'],['FW','0.63 / 0.59','0.39 / 0.43'],['MC','0.76 / 0.79','0.71 / 0.72']],'Records at the other site retain useful prediction','Within groups: moderate DM/FW prediction and high MC prediction.')]:
 s=new(title,'RESULTS · '+scheme,source='Manuscript · Table S5',notes='M3 results. Each pair is Aberystwyth / Braunschweig. Within-group values use population-group-adjusted phenotypes and pooled within-group evaluation. This analysis uses one phenotype per genotype per site. The CV2 information comes from the other trial, not another year at the same trial.');table(s,[['Trait','Across groups','Within groups']]+rows,[1.85,5,5]);txt(s,'M3 · Aberystwyth / Braunschweig · adjusted within-group evaluation',.8,5.85,11.8,.4,17,MUTED);call(s,take)
s=new('Implications for allocating phenotyping effort','BREEDING IMPLICATIONS',notes='The study addresses phenotype measurement allocations rather than proven reductions in plot establishment or maintenance costs. The most direct application is reducing measurement frequency at established perennial trials. It does not justify removing annual harvest management or assume completely new environments can be predicted.');points(s,[('Cover more unique genotypes','Spread measurement effort beyond a small repeatedly measured subset.'),('Use existing candidate records','The strongest predictions use phenotypes from other environments.'),('Target missing annual measurements','The clearest application is established trials with records across years.')])
s=new('Where further validation is needed','LIMITATIONS',notes='Ploidy-specific allele dosage is not represented by the diploid 0/1/2 coding. Larger within-group populations, particularly hybrids, are needed. Environmental covariates could help characterize responses, but improved prediction of new sites remains to be demonstrated.');points(s,[('Small and structured panel','125 genotypes, including only 22 hybrids.'),('Five site-years at two sites','New sites and independent breeding populations need validation.'),('Marker and environmental information','Test allele dosage and climate, soil and management covariates.')])
s=new('Three messages for plant breeders','CONCLUSIONS');points(s,[('Model G×E','The clearest predictive benefits were for DM and FW.'),('Increase genotype coverage','Unique training genotypes explain much of the sparse-design pattern.'),('Validate within-group ranking','Completely untested candidates remain difficult to rank in this panel.')])
s=new('Thank you','',notes='Acknowledge funders, field staff and collaborators. Invite discussion.');txt(s,'Funding',.75,2,11.8,.5,25,GREEN,True);txt(s,'DESNZ Miscanspeed\nBBSRC BB/K01711X/1\nBBS/E/W/0012843A',.75,2.65,11.8,1.7,23);txt(s,'Thanks to IBERS field staff and all collaborators.',.75,4.6,11.8,.7,23);a=txt(s,'Data and code: Miscanthus-Sparse-Testing-Pipeline',.75,5.65,11.8,.6,20,GREEN);a.text_frame.paragraphs[0].runs[0].hyperlink.address='https://github.com/nelsonlubanga/Miscanthus-Sparse-Testing-Pipeline'
# Readable text and a 30-minute speaking plan; discussion is additional.
times=[30,60,75,45,45,60,75,60,90,105,105,105,45,60,75,75,75,75,75,90,90,90,75,60,30]
assert len(r.slides)==len(times)
# Allocate precisely 30 minutes, retaining extra time for the validation slide.
times[11]+=1800-sum(times)
assert sum(times)==1800
for i,(sl,secs) in enumerate(zip(r.slides,times)):
 note=sl.notes_slide.notes_text_frame.text
 sl.notes_slide.notes_text_frame.text=f'Planned speaking time: {secs} seconds. Audience: plant breeders.\n\n'+note
for sl in r.slides:
 for sh in sl.shapes:
  assert sh.left>=0 and sh.top>=0
  assert sh.left+sh.width<=r.slide_width+Inches(.02)
  assert sh.top+sh.height<=r.slide_height+Inches(.02)
out=P/'Miscanthus_Sparse_Testing_Presentation_readable.pptx';r.save(out)
from zipfile import ZipFile
from lxml import etree
with ZipFile(out) as z:
 assert z.testzip() is None
 for n in z.namelist():
  if n.endswith('.xml'):etree.fromstring(z.read(n))
(P/'readable_speaker_notes.md').write_text('\n\n'.join(f'## Slide {i+1}\n'+sl.notes_slide.notes_text_frame.text for i,sl in enumerate(r.slides)))
print(f'Validated {len(r.slides)} slides; 30-minute speaking plan; saved {out}')
