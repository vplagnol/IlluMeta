
pipeline=../scripts/pipeline.sh
outDir=results                                                                                ####### output Directory
sample=example


bash ${pipeline} --outDir ${outDir} --sample $sample --step7_q14 TRUE
