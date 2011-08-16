
pipeline=../scripts/pipeline.sh
outDir=results                                                                                ####### output Directory
sample=example
dbnr=/ugi/home/shared/sofia/reference_seq/nr/nr.faa

bash ${pipeline} --dbnr ${dbnr} --outDir ${outDir} --sample $sample --step6_q14 TRUE    
