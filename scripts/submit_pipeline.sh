pipeline=/ugi/data/sofia/Illumeta/exec/pipeline.sh

input="/ugi/data/sofia/pipeline_results/names.tab"    ################# Modify the sample names in the file


for sample in  `cat ${input}`; do
    echo -e "\n\nSample is $sample"  

   
    prefix=/ugi/data/sofia/Cambridge_viralseq/raw_data/
    myInput=`find $prefix -name *$sample* | sort`
    inputFiles="$myInput"
    echo "Input files are $inputFiles "      
    
    suffix1=fq.gz                                                                                                                      ####### Sanger fastq format
    suffix2=sequence.txt.gz                                                                                                            ###### Illumina Fastq
    delimiter1="."															####delimiter in the name of the file
    delimiter2="_"															#####alternative delimiter --//--			

    referenceHuman=/ugi/home/shared/vincent/reference_genome/novoalign/human_g1k_v37.fasta.k15.s2.novoindex                             ####### novoalign human
    referenceMouse=/ugi/home/shared/vincent/reference_genome/novoalign/Mus_musculus.NCBIM37.61.dna_rm.toplevel.fa.k15.s2.novoindex   	####### novoalign mouse
    dbMouse=/ugi/data/vincent/sequence_database/mouse/mouse_genomic_transcript  							####### blast database Mouse
    dbHuman=/ugi/data/vincent/sequence_database/human_genomic/human_genomic     							####### blast database Human

    output=/ugi/data/sofia/pipeline_results/${sample}/                                                                                   ####### output Directory

    scriptInitial=/ugi/data/sofia/pipeline_cluster/submission/pipeline_initial_${sample}.sh
    scriptStep1=/ugi/data/sofia/pipeline_cluster/submission/pipeline_step1_${sample}.sh							####### script for step1: Collapse, Merge, Novoalign
    scriptStep2=/ugi/data/sofia/pipeline_cluster/submission/pipeline_step2_${sample}.sh							####### script for step2: Blastn
    #### Multiple scripts are created for step3 (blastx reads against viral)
    scriptStep4=/ugi/data/sofia/pipeline_cluster/submission/pipeline_step4_${sample}.sh							####### script for step4: Velvet
    scriptStep5=/ugi/data/sofia/pipeline_cluster/submission/pipeline_step5_${sample}.sh                                                 ####### script for step5: Extract long contigs
    #### Multiple scripts are created for step 6 (blastx contigs agaisnt nr)
    
    local=queue1


    if [ ! -e /ugi/data/sofia/pipeline_results/${sample} ]; then mkdir /ugi/data/sofia/pipeline_results/${sample}; fi

    

####### step1 : Collapse, Merge (if necessary), Novoalign
####### Be careful: choose correctly  Human or Mouse reference (novoindex) -> "reference"
######  Also: choose the correct fastq format -> "suffix"    
        sh ${pipeline} --script ${scriptStep1} --inputFiles ${inputFiles}   --reference ${referenceHuman} --delimiter ${delimiter1} --suffix ${suffix1} --output ${output} --local ${local} --prefix $prefix --sample ${sample} --step1_q1 TRUE


####### step2 (optional, not necessary for serum data)  : Blastn against host
####### Be careful: Set "merged" parameter correctly (check if you have 2 output files from Novoalign -overlapping and nonOverlapping- instead of one)
####### Be careful: choose correctly Human or Mouse blast database -> "db"
        #sh ${pipeline} --script ${scriptStep2} --inputFiles ${inputFiles} --delimiter ${delimiter1} --suffix ${suffix1} --db ${dbHuman} --output ${output}  --local ${local} --prefix $prefix --sample $sample  --step2_q1 TRUE --merged TRUE


####### step3  : Blastx against viral
####### Be careful: Set "merged" parameter correctly
####### Be careful: Set "blastnDone" parameter correctly (depending on whether previous step was implemented)
       #sh ${pipeline} --script ${scriptInitial}  --inputFiles ${inputFiles} --delimiter ${delimiter1} --suffix ${suffix1} --output ${output}  --local ${local} --prefix $prefix --sample $sample  --step3_q14 TRUE --merged TRUE --blastnDone TRUE

####### step4 : Velvet 
###### Be careful: Set "merged" parameter correctly
       #sh ${pipeline} --script ${scriptStep4} --inputFiles ${inputFiles} --delimiter ${delimiter1} --suffix ${suffix1} --output ${output} --local ${local} --prefix $prefix --sample $sample --step4_q1 TRUE --merged TRUE


####### step5 : Extract long contigs 
    #  sh ${pipeline} --script ${scriptStep5} --inputFiles ${inputFiles} --delimiter ${delimiter1} --suffix ${suffix1} --output ${output} --local ${local}  --prefix $prefix --sample $sample --step5_q1 TRUE    
	

###### step6 : Blastx contigs  against NR 
     # sh ${pipeline} --script ${scriptInitial}   --inputFiles ${inputFiles} --delimiter ${delimiter1}  --suffix ${suffix1} --output ${output} --local ${local} --prefix $prefix --sample $sample --step6_q14 TRUE    

	
###### step7 : Extract Viral Contigs  (not submitted on the queue)
      # sh ${pipeline} --script ${scriptInitial}  --inputFiles ${inputFiles} --delimiter ${delimiter1} --suffix ${suffix1} --output ${output}  --local ${local} --prefix $prefix --sample $sample --step7_q14 TRUE
done
