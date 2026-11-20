import sys,re
sys.path.insert(0,'/private/tmp/miscanthus_pptx_deps')
from pathlib import Path
from pptx import Presentation
from pptx.util import Pt, Inches
from pptx.dml.color import RGBColor
from zipfile import ZipFile
from lxml import etree
src=Path('/Users/nel6/Desktop/Documents/Miscathus_others/Sparse_testing/revision/final revision/Miscanthus_Sparse_Testing_Presentation.pptx')
r=Presentation(src)
def settext(shape,text):
 tf=shape.text_frame
 p=tf.paragraphs[0]
 if p.runs:
  p.runs[0].text=text
  for run in list(p.runs)[1:]:run.text=''
 else:p.text=text
 for para in list(tf.paragraphs)[1:]:tf._txBody.remove(para._p)
def replace(sl,old,new):
 for sh in sl.shapes:
  if sh.has_text_frame and old in sh.text:
   settext(sh,sh.text.replace(old,new));return
 raise ValueError(old)
replace(r.slides[2],'Sparse testing: all genotypes are tested in at least one, but not all, environments','Sparse testing: measure a subset of genotype × environment combinations')
replace(r.slides[2],'Overlapping (OL) genotypes are tested in every environment and connect the trials.','Overlapping (OL) genotypes may be measured in every environment, connecting the trials.')
replace(r.slides[12],'Moderate to high, up to 0.95. M3 best for DM and FW; models similar for MC.','Moderate to high, up to 0.95. M3 generally improved prediction for DM and FW; models similar for MC.')
replace(r.slides[15],'Across-panel accuracy mostly reflects group differences','Group differences inflate predictive ability most strongly under CV1')
replace(r.slides[15],'CV2 · genotypes tested in at least one, but not all, environments','CV2 · phenotyped at the other site')
replace(r.slides[16],'With a fixed budget, spread plots across more distinct genotypes rather than repeating a few everywhere.','Spread phenotyping effort across more unique genotypes. The clearest application is fewer annual measurements in established trials.')
replace(r.slides[16],'GP ranked genotypes within groups well only once they had been phenotyped at one site.','Within-group prediction was moderate for DM/FW and high for MC when candidates were phenotyped at the other site.')
replace(r.slides[18],'Within groups, untested genotypes were hard to rank; genotypes phenotyped at another site were not.','Within-group prediction remained moderate for DM/FW and high for MC when candidates were phenotyped at the other site.')
for sl in r.slides:
 for sh in list(sl.shapes):
  if sh.has_text_frame and sh.text.strip()=='PLANT BREEDING · 30-MINUTE SEMINAR':
   sh._element.getparent().remove(sh._element)
  if sh.has_table:
   for row in sh.table.rows:
    for cell in row.cells:
     if 'hadamant' in cell.text:
      for p in cell.text_frame.paragraphs:
       for run in p.runs:run.text=run.text.replace('hadamant','Hadamard')
# Keep the combined models-and-scenarios slide; remove the preceding duplicate model slide.
sid=r.slides._sldIdLst[6];r.part.drop_rel(sid.rId);r.slides._sldIdLst.remove(sid)
# Replace old slide numbers and number all slides consistently.
for i,sl in enumerate(r.slides,1):
 for sh in list(sl.shapes):
  if sh.has_text_frame and re.fullmatch(r'\d{1,2}',sh.text.strip()) and sh.top>r.slide_height-Inches(.7):
   sh._element.getparent().remove(sh._element)
 tb=sl.shapes.add_textbox(r.slide_width-Inches(.65),r.slide_height-Inches(.38),Inches(.45),Inches(.25))
 p=tb.text_frame.paragraphs[0];p.text=f'{i:02}';p.font.size=Pt(10);p.font.color.rgb=RGBColor(82,100,94)
# Reduce the longer replacement conclusion to fit its existing box.
for sl in r.slides:
 for sh in sl.shapes:
  if sh.has_text_frame and (sh.text.startswith('Within-group prediction remained') or sh.text.startswith('Group differences inflate')):
   for p in sh.text_frame.paragraphs:
    for run in p.runs:
     if run.font.size and run.font.size>Pt(24):run.font.size=Pt(24)
out=Path(__file__).parent/'Miscanthus_Sparse_Testing_Presentation_revised.pptx'
r.save(out)
with ZipFile(out) as z:
 assert z.testzip() is None
 for n in z.namelist():
  if n.endswith('.xml'):etree.fromstring(z.read(n))
check=Presentation(out)
assert len(check.slides)==19
alltext=' '.join(sh.text for sl in check.slides for sh in sl.shapes if sh.has_text_frame)
assert 'PLANT BREEDING · 30-MINUTE SEMINAR' not in alltext
assert 'spread plots' not in alltext
assert 'Hadamard' in ' '.join(c.text for sl in check.slides for sh in sl.shapes if sh.has_table for row in sh.table.rows for c in row.cells)
print(out.resolve())
