pipeline=../scripts/pipeline.sh
referenceHuman=/ugi/home/shared/vincent/reference_genome/novoalign/human_g1k_v37.fasta.k15.s2.novoindex                             ####### novoalign human
outDir=results                                                                                    ####### output Directory
local=queue1
scriptStep1=cluster/submission/step1.sh
sample=example

inputFiles="2 input_files/example.1.fq.gz input_files/example.2.fq.gz"


bash ${pipeline} --script ${scriptStep1} --inputFiles ${inputFiles}   --reference ${referenceHuman} --outDir ${outDir} --sample ${sample} --local ${local} --step1_q1 TRUE 
