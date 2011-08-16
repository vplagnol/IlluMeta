
pipeline=../scripts/pipeline.sh
outDir=results                                                                                    ####### output Directory
sample=example
dbViral=/ugi/data/vincent/sequence_database/viral/viral.protein.faa



bash ${pipeline} --outDir ${outDir}  --dbViral ${dbViral} --sample $sample  --step3_q14 TRUE --merged TRUE --blastnDone TRUE
