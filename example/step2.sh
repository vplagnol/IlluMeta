
pipeline=../scripts/pipeline.sh
outDir=results                                                                                    ####### output Directory
local=queue1
scriptStep2=cluster/submission/step2.sh
sample=example
dbHuman=/ugi/data/vincent/sequence_database/human_genomic/human_genomic 

bash ${pipeline} --script ${scriptStep2} --db ${dbHuman} --outDir ${outDir}  --local ${local} --sample $sample  --step2_q1 TRUE --merged TRUE
