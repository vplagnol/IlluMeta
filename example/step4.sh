

pipeline=../scripts/pipeline.sh
outDir=results                                                                                ####### output Directory
sample=example
scriptStep4=cluster/submission/step4.sh
local=queue1

bash ${pipeline} --script ${scriptStep4} --outDir ${outDir} --local ${local} --sample $sample --step4_q1 TRUE --merged TRUE
