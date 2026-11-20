import sys
sys.path.insert(0, '/private/tmp/miscanthus_pptx_deps')
from pathlib import Path
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from PIL import Image
P=Path(__file__).resolve().parent
r=Presentation(); r.slide_width=Inches(13.333); r.slide_height=Inches(7.5)
BG='F6F7F2'; INK='173C35'; GREEN='287C65'; MUTED='52645E'; GOLD='D8A643'; WHITE='FFFFFF'
def box(s,x,y,w,h,color):
 a=s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h)); a.fill.solid(); a.fill.fore_color.rgb=RGBColor.from_string(color); a.line.fill.background(); return a
def txt(s,t,x,y,w,h,size=22,color=INK,bold=False):
 a=s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h)); f=a.text_frame; f.word_wrap=True
 for i,line in enumerate(t.split('\n')):
  p=f.paragraphs[0] if i==0 else f.add_paragraph(); p.text=line; p.font.name='Aptos'; p.font.size=Pt(size); p.font.bold=bold;p.font.color.rgb=RGBColor.from_string(color);p.space_after=Pt(12)
 return a
def slide(title,kicker='PLANT BREEDING · 30-MINUTE SEMINAR',notes='',source='Manuscript: Lubanga et al., supplied clean submission'):
 s=r.slides.add_slide(r.slide_layouts[6]);s.background.fill.solid();s.background.fill.fore_color.rgb=RGBColor.from_string(BG)
 box(s,0,0,0.16,7.5,GREEN);txt(s,kicker,0.55,0.24,12,0.35,11,GREEN,True);txt(s,title,0.55,0.8,12.2,1.05,30,INK,True)
 txt(s,source,0.55,7.05,11.7,0.25,9,MUTED);txt(s,f'{len(r.slides):02d}',12.35,7.0,0.5,0.3,11,MUTED)
 s.notes_slide.notes_text_frame.text=notes+'\n\nSource: '+source
 return s
def pic(s,name,x,y,w,h):
 p=P/name; iw,ih=Image.open(p).size;scale=min(w/iw,h/ih);ww=iw*scale;hh=ih*scale
 s.shapes.add_picture(str(p),Inches(x+(w-ww)/2),Inches(y+(h-hh)/2),width=Inches(ww),height=Inches(hh))
def call(s,t,y=6.15):
 box(s,.55,y,12.2,.65,INK);txt(s,t,.78,y+.1,11.75,.48,18,WHITE)
def cards(s,items):
 w=11.9/len(items)
 for i,(a,b) in enumerate(items):
  x=.65+i*w;box(s,x,2.15,w-.18,3.75,WHITE);txt(s,a,x+.22,2.4,w-.6,.8,29,GREEN,True);txt(s,b,x+.22,3.2,w-.6,2.6,19)
# 1
s=slide('Sparse testing and multi-environment\ngenomic prediction in Miscanthus',notes='Opening (~40 seconds). This talk asks how to use a fixed phenotyping budget more effectively in a structured perennial breeding population. The central distinction is between predicting completely untested candidates and filling missing observations for candidates already phenotyped elsewhere.')
txt(s,'Designing trials to support selection within a fixed phenotyping budget',.65,3.0,12,0.7,25,GREEN)
txt(s,'Nelson Lubanga, Iain Donnison, Chris Davey, Beatrice Ifie,\nGancho Slavov, Kerrie Farrar and Diego Jarquin',.65,4.2,12,1.0,21)
txt(s,'Aberystwyth University • Oregon State University • University of Florida',.65,5.6,12,.6,16,MUTED)
# 2
s=slide('How far can a fixed phenotyping budget go?',notes='Motivation (~50 seconds). Miscanthus is a perennial C4 biomass crop. Multi-year evaluation and genotype by environment interaction make selection expensive. Sparse testing measures subsets of genotypes in environments, then predicts missing combinations. Ask whether performance comes from genomic prediction, previous measurements or broad population differences.')
cards(s,[('The constraint','Multi-year trials are expensive; G×E complicates selection.'),('The strategy','Measure subsets of genotypes and predict missing combinations.'),('The test','Can we rank candidates within breeding groups?')]);call(s,'Three questions: model G×E, allocate phenotyping, and account for population structure.')
# 3
s=slide('125 genotypes across five site-year environments',notes='Study design (~50 seconds). The panel contains 47 M. sinensis, 56 M. sacchariflorus and 22 interspecific hybrids. Not every genotype has a phenotype in every environment. DM and FW are biomass traits; MC is moisture content. Marker filtering retained 13,687 SNPs, with 11,901 contributing to the relationship matrix used for prediction; see technical backup.')
cards(s,[('125 genotypes','47 M. sinensis\n56 M. sacchariflorus\n22 interspecific hybrids'),('Two field sites','Aberystwyth, UK\n2015 and 2016\n\nBraunschweig, Germany\n2014, 2015 and 2016'),('Three traits','Dry matter yield (DM)\nFresh weight (FW)\nMoisture content (MC)')]);call(s,'Five environments are site × year combinations; the same plants recur across years.')
# 4 crop original
im=Image.open(P/'image1.png');im.crop((0,0,1100,590)).save(P/'pca_panel.png')
s=slide('Can we rank candidates within a breeding group?',source='Manuscript: Figure 1a; population genetic structure; within-group analyses',notes='Population structure (~50 seconds). PC1 explains 22.57% of marker variation and separates the two species with hybrids intermediate. These groups also differ in trait means. Group differences can increase across-panel prediction correlations without establishing useful within-group ranking. Population group explained 22–34% of trial-level phenotype variation.')
pic(s,'pca_panel.png',.65,2.0,7.3,4.5);txt(s,'Three genetic groups\n\nPC1: 22.57% of marker variation\n\nGroup differences can elevate across-panel predictive ability.',8.25,2.25,4.35,3.9,23)
# 5
s=slide('What do markers and G×E add to existing trial records?',notes='Models (~60 seconds). Stage one estimates genotype BLUEs in each environment using site-specific mixed models. Stage two fits the three models in BGLR. Population group is a fixed effect in the main prediction analyses. L is a non-marker genotype effect, G a genomic effect. M3 adds the genomic by environment covariance. M1 has no marker information and provides a useful phenotypic baseline for CV2.')
cards(s,[('M1 · Baseline','Environment\nPopulation group\nGenotype'),('M2 · Genomic','All terms in M1\n+ genomic main effect'),('M3 · G×E','All terms in M2\n+ genomic × environment interaction')]);call(s,'Genotype BLUEs → multi-environment prediction → correlation with held-out BLUEs')
# 6
s=slide('CV1 and CV2 answer different breeding questions',notes='Validation (~60 seconds). CV1 masks all records for a genotype. CV2 masks selected genotype by environment observations while retaining other observations of that genotype. Both use random five-fold cross-validation. A missing year at a tested site is easier than prediction at an untested site. The separate two-trial analysis combines years before validation to assess transfer between sites without same-site year information.')
cards(s,[('CV1 · Untested','All records of a candidate are masked.\n\nCan markers predict a new genotype?'),('CV2 · Partly tested','Some records are masked; others remain.\n\nCan other environments inform missing observations?')]);call(s,'Site-year CV2 may use another year at the same site; it does not validate a new site.')
# 7
s=slide('G×E accounts for meaningful trait variation',source='Manuscript: Figure 2; variance components',notes='Variance components (~45 seconds). In the full-data variance decomposition population group was random, unlike in the main prediction models. G×E accounts for 13.2% of total variance in DM, 16.9% in FW and 14.5% in MC under M3. Residual variance is lower in M3 relative to M1 by 50%, 59% and 45%. These are model comparisons, not guaranteed gains in predictive ability. Only five environments and three groups inform the corresponding variance estimates.')
pic(s,'image2.png',.65,1.95,8.5,4.7);txt(s,'G×E share in M3\n\nDM   13.2%\nFW   16.9%\nMC   14.5%',9.5,2.2,3.1,3.4,25)
# 8
s=slide('CV2 generally predicts better than CV1',source='Manuscript: Figure 3a and Figure 3b',notes='Prediction across site-years (~70 seconds). Top panel is CV1 and bottom panel CV2. M3 generally improves DM and FW, but no model consistently wins for MC. The distributions show variation across cross-validation partitions; avoid presenting the most extreme correlations as expected performance. CV2 benefits from phenotypes in other site-years, including repeated years at a site.')
pic(s,'image3.png',.65,1.85,9.5,2.35);pic(s,'image4.png',.65,4.35,9.5,2.35);txt(s,'CV1\nUntested\ngenotypes',10.45,2.2,2.4,1.5,22,GREEN,True);txt(s,'CV2\nPartly tested\ngenotypes',10.45,4.7,2.4,1.5,22,GREEN,True)
# Breeder-focused worked design example
s=slide('Two ways to spend 125 phenotype measurements',source='Manuscript: Table 1; illustrative allocation schematic',notes='Worked example. Keep both the total number of measurements and the number per environment fixed. Under the all-overlap design the same 25 genotypes are measured in each of five environments. Under the all-non-overlap design five different sets of 25 genotypes are measured, representing 125 unique candidates. This is an allocation of phenotyping effort rather than a demonstrated reduction in planting, maintenance or harvesting costs. Ask the audience to distinguish the number of candidates covered from the depth of measurement for each candidate. Intermediate designs trade these two quantities. Genomic relationships connect candidates even when individual genotypes are not shared.')
for x,head,counts in [(0.7,'Repeated coverage · 25 unique',[25]*5),(7.0,'Broader coverage · 125 unique',[25]*5)]:
 txt(s,head,x,1.95,5.6,.65,23,GREEN,True)
 for j,n in enumerate(counts):
  y=2.85+j*.48
  txt(s,f'E{j+1}',x,y,.6,.35,17)
  for k in range(5):box(s,x+.8+k*.71,y,.56,.28,GREEN if x<1 else ['287C65','4A8475','709E87','A4B795','D8A643'][j])
 txt(s,'Same candidates in each environment' if x<1 else 'Different candidates in each environment',x,5.5,5.6,.55,18)
call(s,'Each row represents 25 measurements; colours indicate shared or distinct genotype sets.')
# 9
s=slide('Sparse designs keep evaluations fixed at 125',source='Manuscript: Table 1',notes='Sparse design (~60 seconds). Every design assigns 25 evaluations per environment, 125 in total. OL genotypes are measured in all five environments; each NOL genotype is measured in one environment. Thus D1 represents 125 unique genotypes, while D6 represents only 25. NOL and OL percentages describe the per-environment allocation. Designs were independently replicated ten times. The 625 possible combinations are nominal; not every combination has an observed phenotype.')
rows=[['Design','NOL per environment','OL per environment','Unique genotypes'],['D1','25','0','125'],['D2','20','5','105'],['D3','15','10','85'],['D4','10','15','65'],['D5','5','20','45'],['D6','0','25','25']]
t=s.shapes.add_table(7,4,Inches(.65),Inches(1.95),Inches(12),Inches(3.85)).table
for i,row in enumerate(rows):
 for j,v in enumerate(row):
  c=t.cell(i,j);c.text=v;c.fill.solid();c.fill.fore_color.rgb=RGBColor.from_string(INK if i==0 else ('FFFFFF' if i%2 else 'E8EEE8'))
  for p in c.text_frame.paragraphs:p.font.size=Pt(18);p.font.color.rgb=RGBColor.from_string(WHITE if i==0 else INK)
call(s,'More overlap means fewer unique training genotypes in this fixed-budget comparison.')
#10
s=slide('Broader genotype coverage gives better sparse predictions',source='Manuscript: Figure 4; sparse-testing results',notes='Sparse prediction (~60 seconds). Read the x axis carefully: NOL decreases from left to right. Prediction is generally best with more NOL genotypes, with M3 highest for DM and FW in each configuration. MC does not show a consistent M3 advantage. These results do not identify a universal optimum overlap fraction because unique genotype coverage changes simultaneously.')
pic(s,'image5.png',.65,2.0,12,3.9);call(s,'The design comparison combines changes in overlap with changes in genotype coverage.')
#11
s=slide('Unique genotype coverage explains much of the pattern',source='Manuscript: fixed-unique-genotype analysis; Figure S2 and Table S3 (described in text)',notes='Sensitivity analysis (~50 seconds). Holding unique genotype number constant within two-, three- or four-environment subsets, prediction varies relatively little as overlap changes. The respective ranges are 0.43–0.44, 0.41–0.43 and 0.38–0.44. These subsets differ from the original five-environment series, so this is supporting evidence, not a full causal isolation. Supplementary figure and data are not embedded in the supplied document; displayed values come from the results text.')
cards(s,[('2 environments','40 unique genotypes\n\nPredictive ability\n0.43–0.44'),('3 environments','36 unique genotypes\n\nPredictive ability\n0.41–0.43'),('4 environments','32 unique genotypes\n\nPredictive ability\n0.38–0.44')]);call(s,'When genotype number is fixed, changing overlap produces relatively small differences.')
#12
s=slide('Untested candidates are harder to rank within groups',source='Manuscript: Figure 5; Table S5 values reported in results',notes='Within-group CV1 (~70 seconds). Years were combined to give one phenotype per genotype per site, avoiding repeated-year information. With M3, across-group correlations are 0.50–0.54 but adjusted pooled within-group correlations are only 0.08–0.27 across traits and trials. These ranges summarize different trait/site combinations rather than matched endpoints. Pooled within-group evaluation centers observed and predicted phenotypes by population group. M1 is omitted because ranking untested candidates without genomic information is undefined in this analysis.')
pic(s,'image6.png',.65,2.05,12,3.4);call(s,'M3: across groups 0.50–0.54; adjusted pooled within groups 0.08–0.27.',5.8)
#13
s=slide('Phenotyping at the other site retains useful prediction',source='Manuscript: Figure 6; across-group and within-group results',notes='Within-group CV2 (~70 seconds). This analysis has one phenotype per genotype per site, so information comes from the other field trial rather than a previous year at the same trial. Adjusted pooled within-group correlations remain 0.39–0.46 for DM and FW, and 0.71–0.72 for MC under M3. The marker-free M1 already reaches 0.25–0.40 for DM/FW and 0.67–0.70 for MC. M3 improves by 0.06–0.14 and 0.02–0.04 respectively, indicating that prior phenotype information contributes substantially.')
pic(s,'image7.png',.65,2.05,12,3.4);call(s,'Adjusted within-group M3: DM/FW 0.39–0.46; MC 0.71–0.72.',5.8)
# Practical interpretation of selection targets
s=slide('Match the prediction to the selection decision',source='Interpretation of manuscript CV1, site-year CV2 and two-trial CV2 analyses',notes='Breeder decision guide. For completely new candidates, within-group CV1 is the relevant result and is low in this panel. For established material with records elsewhere, CV2 supports filling missing phenotypes, with the two-trial analysis providing a stronger test of transfer between the two represented sites. Neither scenario demonstrates prediction at an entirely new site. These correlations describe agreement with observed BLUEs; they are not measured selection response or genetic gain. A practical next step is a prospective comparison of selected candidates, maintaining a validation set with direct measurements.')
cards(s,[('New candidates','No phenotype records.\n\nJudge within-group CV1.\n\nRanking was weak in this panel.'),('Established material','Records in another year or trial.\n\nCV2 supports filling gaps.\n\nCheck which records are available.'),('New target site','Environment not represented in training.\n\nRequires independent validation.\n\nNot established by this study.')]);call(s,'Predictive ability is a correlation with observed performance; realised selection gain was not tested.')
# Seminar detail: validation
s=slide('Two validation steps answer different questions',source='Manuscript: cross-validation and within-group assessment methods',notes='Explain the two levels of validation slowly. First, site-year validation retains five environments and assesses missing observations or entirely withheld genotypes. In perennial material, another year of the same plants can be available under CV2. Second, the trial-level analysis collapses all years into a single BLUE for each genotype at each site. Withholding that trial-level record removes the same-site repeated-year information. Group means used for phenotype adjustment are estimated from training data only. At evaluation, observed and predicted values are centred by population group to measure pooled within-group ranking. This is a pooled correlation of deviations, not an average of three separate group correlations. Matched partitions make model comparisons more informative. Correlations with phenotype BLUEs do not directly estimate correlation with true breeding values or realised genetic gain.')
cards(s,[('Site × year analysis','Five environments.\n\nCV2 can use another year at the same site.\n\nRelevant to missing annual records.'),('Two-trial analysis','One BLUE per genotype per site.\n\nCV2 uses the other trial.\n\nRemoves same-site year information.'),('Within-group ranking','Adjust using training group means.\n\nEvaluate centred predictions and BLUEs.\n\nFocus on candidate differences within groups.')]);call(s,'Validation should reproduce the information available when the breeder makes a decision.')
# Seminar detail: prospective deployment
s=slide('A practical pilot before changing routine phenotyping',source='Proposed breeding-programme application, informed by manuscript findings',notes='This is a proposed pilot rather than an intervention tested in the manuscript. Define whether the aim is to fill missing annual records, predict candidates at another represented site, or select completely untested material. Retrospectively mask complete candidate or site-year records to match that aim. Compare a marker-free baseline with genomic and genomic-by-environment models using identical partitions. Keep directly measured validation candidates to check within-group ranking and agreement among selected candidates. Test a modest change in annual measurement coverage in established trials while retaining the observations needed for validation. Measure actual labour and laboratory savings separately from plot maintenance and harvesting costs. Decisions about shared checks and replication should depend on the programme and require a design study; this manuscript does not establish a universal overlap optimum.')
cards(s,[('1 · Define the decision','Choose the prediction target.\n\nMatch masking to records available at selection.'),('2 · Retain validation','Measure held-out candidates.\n\nCheck within-group ranking and selection agreement.'),('3 · Compare costs','Track phenotyping labour and assays.\n\nSeparate measurement savings from plot costs.')]);call(s,'Proposed pilot: validate prediction and resource savings before scaling the design.')
#14
s=slide('Use sparse testing where information already exists',notes='Implications and limitations (~60 seconds). The evidence most directly supports reducing annual measurement effort in established trials, while increasing unique genotype coverage. It does not establish that the same cost savings apply to plot establishment, annual harvest management or new sites. There was no direct economic analysis. Training panels should be larger within groups; hybrid sample size is particularly small. Independent populations and environments are required for broader validation.')
cards(s,[('Apply now','Prioritise unique genotype coverage.\n\nUse G×E models for biomass traits.\n\nAssess within-group ranking.'),('Interpret carefully','Same-site years support CV2.\n\nOnly 125 genotypes and five site-years.\n\nMixed ploidy lacks dosage modelling.'),('Validate next','Larger within-group panels.\n\nIndependent sites and populations.\n\nEnvironmental covariates and costs.')]);call(s,'The strongest immediate application is filling missing years at established trials.')
#15
s=slide('More genotype coverage, with realistic prediction targets',kicker='TAKE-HOME MESSAGES',notes='Close (~45 seconds). Emphasise three conclusions: adding G×E helps most clearly for biomass traits, unique genotype coverage matters in these budget-limited sparse designs, and phenotyping elsewhere is crucial for useful within-group prediction. Thank the field staff and funders, then invite questions. Main seminar ends here; remaining slides are backup.')
txt(s,'01   Model G×E for DM and FW.\n\n02   Spread phenotyping across more unique genotypes.\n\n03   Use within-group validation to judge selection value.',.8,2.0,11.8,3.1,28,INK,True)
txt(s,'Thanks to IBERS field staff and collaborators.\nFunding: DESNZ Miscanspeed; BBSRC BB/K01711X/1 and BBS/E/W/0012843A.',.8,5.65,11.8,.9,16,MUTED)
#16
s=slide('Phenotypic variation and heritability',kicker='BACKUP · TRAIT CONTEXT',source='Manuscript: Figure 1b and Table 4',notes='Backup. H² with population group fixed reflects within-group genetic variation: DM 0.70–0.80, FW 0.75–0.84, MC 0.52–0.92. These are entry-mean broad-sense heritabilities rather than prediction accuracies. Hybrids have highest DM and FW in every environment. M. sacchariflorus has lowest median MC. Mean phenotypic ranges are DM 0.27–2.70 kg, FW 0.34–4.04 kg and MC 16.17–31.66%.')
im.crop((0,590,1100,1513)).save(P/'phenotypes_panel.png');pic(s,'phenotypes_panel.png',.65,1.95,7.8,4.8);txt(s,'Within-group H² ranges\n\nDM   0.70–0.80\nFW   0.75–0.84\nMC   0.52–0.92',8.7,2.3,4.0,3.6,24)
#17
s=slide('Marker processing and relationship-matrix sensitivity',kicker='BACKUP · GENOTYPING',notes='Backup. RAD-seq yielded 25,014 SNPs in the source panel. Quality control within the 125 genotypes retained 13,687 markers. Using 0/1/2 coding with A.mat, which expects minus one/zero/one coding, resulted in 11,901 SNPs contributing to the matrix used for prediction. The correctly coded matrix from 13,687 SNPs was almost identical and changed predictive ability by at most 0.033. Figure 2 variance components use that corrected matrix. No ploidy-specific allele dosage was represented.')
cards(s,[('Quality control','25,014 source SNPs\n↓\n13,687 after subset QC\n\nMean genotype imputation'),('Prediction matrix','11,901 contributing SNPs\n\n0/1/2 supplied to A.mat\n(expected −1/0/1)'),('Sensitivity check','Correctly coded 13,687-SNP matrix:\n\nOff-diagonal r = 0.999\nMaximum change in predictive ability: 0.033')])
#18
s=slide('Evaluation separates group means from ranking',kicker='BACKUP · VALIDATION',source='Manuscript: Section 2.9.1; data availability',notes='Backup. In the two-trial analysis group-adjusted phenotypes subtract trial by population-group means estimated only from training data; training means are added back to predictions. Evaluation then centers both predictions and observations by group to calculate pooled within-group correlations. This evaluation centering is distinct from training adjustment. Identical partitions are used for adjusted and unadjusted analyses. BGLR two-trial runs use 8,000 iterations, 2,000 burn-in and thinning five. Five-fold validation is repeated ten times.')
txt(s,'One BLUE per genotype per site, combining years.\n\nTraining adjustment uses training-set group means only.\n\nWithin-group evaluation centres predictions and observations by group.\n\nIdentical partitions: five folds × 10 repetitions.',.8,1.95,11.8,3.9,24)
a=txt(s,'Analysis repository: Miscanthus-Sparse-Testing-Pipeline',.8,6.1,11.8,.6,18,GREEN);a.text_frame.paragraphs[0].runs[0].hyperlink.address='https://github.com/nelsonlubanga/Miscanthus-Sparse-Testing-Pipeline'
r.core_properties.title='Sparse testing and multi-environment genomic prediction in Miscanthus'
r.core_properties.author='Nelson Lubanga et al.'
r.core_properties.subject='Research presentation based on Manuscript_submission_clean.docx'
# Main seminar is 30 minutes; discussion and backup slides are additional.
minutes=[0.75,1.5,1.25,1.5,1.5,2,1.25,2,1.5,1.5,1.75,1.5,2,2,1.75,2,1.75,1.5,0.5]
minutes[7]+=30-sum(minutes)
assert abs(sum(minutes)-30)<0.001
import re
for i,sl in enumerate(r.slides):
 n=sl.notes_slide.notes_text_frame.text
 n=re.sub(r'\s*\(~\d+ seconds\)', '', n)
 if i<19:
  sl.notes_slide.notes_text_frame.text=f'PLANNED TIME: {int(minutes[i]*60)} seconds. Audience: plant breeders.\n\n'+n
 else:sl.notes_slide.notes_text_frame.text='BACKUP: outside the 30-minute main seminar.\n\n'+n
out=P/'Miscanthus_Sparse_Testing_Presentation.pptx';r.save(out)
# Check package validity, slide dimensions and notes.
from zipfile import ZipFile
from lxml import etree
with ZipFile(out) as z:
 assert z.testzip() is None
 for n in z.namelist():
  if n.endswith('.xml'):etree.fromstring(z.read(n))
assert len(r.slides)==22
for s in r.slides:
 assert s.notes_slide.notes_text_frame.text.strip()
 for sh in s.shapes:
  assert sh.left>=0 and sh.top>=0
  assert sh.left+sh.width<=r.slide_width+Inches(.02)
  assert sh.top+sh.height<=r.slide_height+Inches(.02)
(P/'speaker_notes.md').write_text('\n\n'.join(f'## Slide {i+1}\n'+s.notes_slide.notes_text_frame.text for i,s in enumerate(r.slides)))
print(f'Created and validated {out}: {len(r.slides)} slides, all with speaker notes.')
