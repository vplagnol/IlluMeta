


pipeline=../scripts/pipeline.sh
outDir=results                                                                                ####### output Directory
sample=example
scriptStep5=cluster/submission/step5.sh
local=queue1

bash ${pipeline} --script ${scriptStep5} --outDir ${outDir} --local ${local}  --sample $sample --step5_q1 TRUE    
