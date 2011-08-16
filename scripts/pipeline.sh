
########### Here is the one line that needs to be modified
Illumeta=/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta


########## everything else below should be automated
Software=${Illumeta}/exec
fastqCollapse=${Software}/fastqCollapse/fastqCollapse
concatReads=${Software}/SHERAc/concatReads
blastn=${Software}/ncbi-blast-2.2.24+/bin/blastn
novoalign=${Software}/novoalign
velveth=${Software}/velvet_1.0.18/velveth
velvetg=${Software}/velvet_1.0.18/velvetg
perlBlastx=${Illumeta}/scripts/NM_blastx.pl
perlExtractContigs=${Illumeta}/scripts/extract_largeContigs.pl
perlBlastxContigs=${Illumeta}/scripts/blastx_Viralcontigs_nr.pl


dbViral=/ugi/data/vincent/sequence_database/viral/viral.protein.faa
dbnr=/ugi/home/shared/sofia/reference_seq/nr/nr.faa


############ default values
local=interactive
lanenumber1=1
contigLengthCutoff=140
script=cluster/submission/default.sh

step1_q1=FALSE
step2_q1=FALSE
step3_q14=FALSE
step4_q1=FALSE
step5_q1=FALSE
step6_q14=FALSE
step7_q14=FALSE
blastnDone=FALSE


until [ -z "$1" ]; do
	# use a case statement to test vars. we always test $1 and shift at the end of the for block.
    case $1 in
	--inputFiles)
	    shift
	    i=0
	    for fileloc in $@; do 
		inputFiles[ $i ]=$fileloc
		((i=i+1))
	    done;;
	--local )
	    shift
	    local=$1;;
	--outDir )
	    shift
	    output=$1;;
	--type )
	     shift
	     type=$1;;
	--script)
	    shift
	    script=$1;;
	 --reference)
            shift
            reference=$1;;
	 --db )
	   shift
	   db=$1;;
	--dbViral)
	    shift
	    dbViral=$1;;
	--dbnr)
	    shift
	    dbnr=$1;;
         --sample )
           shift
           sample=$1;;
	--step1_q1 )
	    shift
	    step1_q1=$1;;
	--step2_q1 )
	    shift
	    step2_q1=$1;;
	--step3_q14 )   
           shift
           step3_q14=$1;;
	--step4_q1 )
	    shift
	    step4_q1=$1;;
	--step5_q1 )
	    shift
	    step5_q1=$1;;
	--step6_q14 )
	    shift
	    step6_q14=$1;;
        --step7_q14 )
            shift
            step7_q14=$1;;
	--merged )
	    shift
	    merged=$1;;
	--blastnDone )
	    shift
	    blastnDone=$1;;	
	--skipping )
	    shift
	    skipping=$1;;
	-* )
	    echo "Unrecognized option: $1"
	    exit 1;;
    esac
    shift
    if [ "$#" = "0" ]; then break; fi
done 


################ creating all the output folders
echo -e "Output folder: $output\n"



output_velvet=${output}/velvet
output_velvet_input=${output_velvet}/input
contigs_subsetted=${output_velvet}/contigs_subsetted

output_blastx=${output}/blastx
output_subsetted=${output_blastx}/subsetted

output_merged=${output}/merged
output_collapsed=${output}/collapsed
output_blastn=${output}/blastn
output_novoalign=${output}/novoalign
output_final=${output}/final


myFolders="cluster cluster/out cluster/error cluster/submission $output $output_velvet $output_velvet_input $output_merged $output_collapsed $output_blastn $output_blastx $output_novoalign $output_final $output_subsetted $contigs_subsetted"

for folder in $myFolders; do
    if [ ! -e $folder ]; then 
	echo "Creating $folder"
	mkdir $folder
    fi
done




################################################################### Now writing the script

echo "Output script:  $script"

echo "
#!/bin/bash
#$ -S /bin/bash

date ##to measure the duration


" > $script



######################################################################################### STEP1 (all steps up to aligning)

if [[ "$step1_q1" == "TRUE" ]]; then

    
    nfiles=${inputFiles[0]}
    
    if [[ "$nfiles" != "2" ]]; then
	echo "You specified $nfiles input files".
	echo "Error: currently the input data MUST be paired end."
	exit;
    fi
    

    seq1=${inputFiles[ 1 ]}
    seq2=${inputFiles[ 2 ]}


###############  check that raw data files & reference exist
    for file in $seq1 $seq2 $reference; do
	ls -lh $file
	if [ ! -e "$file" ]; then 
	    echo "Error, file $file does not exist"
	    exit
	fi
    done


#################################################################  Collapsing
    echo "1) Collapse paired reads"

    summaryfile=${sample}_summary.txt
    
    echo "

${fastqCollapse}  -i $seq1 $seq2 -o ${output_collapsed}/${sample} -summary ${output_collapsed}/${summaryfile}

" >> $script


################################################################ Merging
    echo "2) Merge Reads"
    
    echo "

${concatReads} --adaptersFile ../support/adapters.fa ${output_collapsed}/${sample}_1.fq  ${output_collapsed}/${sample}_2.fq  ${output_merged}/${sample}

" >> $script
    

################################################################ Check whether merging necessary 
    
    echo -e "3) Is merging necessary? Print merged percentage."

    echo "

awk -F":" '{if ((\$1~/Sequences Processed/) || (\$1~/Sequences Overlapping/)) print \$2}' ${output_merged}/$sample.summary  | awk '{ a[\$0] } END {for (i in a){for (j in a){if (i < j)  print (i/j)*100} }}' > ${output}/percentage_merged.txt

" >> $script




################################################################# Novoalign

    echo -e "4a) Merged data more than 10% -> Align merged (single end) and remaining (paired end) against host."
    echo -e "4b) Merged data less than 10% -> Align original collapsed files (only paired end data) against host."


    echo "

percentage=\`awk -F\".\" '{print \$1}' ${output}/percentage_merged.txt\`

if [[ \$percentage -ge 10 ]]; then
############## Hardclipping but no quality calibration
${novoalign} -t180  -H -a  -F STDFQ -f ${output_merged}/$sample.fq -d $reference > ${output_novoalign}/${sample}_overlapping.novo
${novoalign}  -t250 -H -a  -F STDFQ -f ${output_merged}/${sample}_single_1.fq ${output_merged}/${sample}_single_2.fq -d $reference > ${output_novoalign}/${sample}_nonOverlapping.novo

else
############# Hardclipping and quality calibration
${novoalign}  -t250 -H -a -k -F STDFQ -f ${output_collapsed}/${sample}_1.fq ${output_collapsed}/${sample}_2.fq -d $reference > ${output_novoalign}/${sample}.novo

fi

" >> $script


echo -e "5) Select pairs of reads that are both NM ->make txt and fasta files. When merged, select all NM ones."


echo " 
novofiles="${output_novoalign}/*.novo"
echo "Novoalign files are '$novofiles'"


for i in \$novofiles
do
    echo "Print '$i'"
    filename=\`basename \$i .novo\`
    echo "Filename is '$filename'"


    if [[ \$filename == *_overlapping* ]]; then
	awk -F\"\\t\" 'BEGIN {OFS=\"\\t\"} {if (\$5~/NM/) print \$1,\$3}'  \$i |  uniq > ${output_novoalign}/NM_\$filename.txt
	wc -l ${output_novoalign}/NM_\$filename.txt > ${output_novoalign}/NM.number
	awk '{print \">\"\$1\"\n\"\$2}' ${output_novoalign}/NM_\$filename.txt > ${output_novoalign}/NM_\$filename.fasta

    else

	awk -F\"\\t\" '{if (\$5~/NM/) print \$1, \$3}'  \$i |  uniq > ${output_novoalign}/NM_\$filename.txt
	awk -F\"\\t\" '{split(\$1, a, \"/\");  print a[1], \$1, \$2}' ${output_novoalign}/NM_\$filename.txt > NM_\${filename}_tmp.txt
	awk 'BEGIN {OFS=\"\\t\"}FNR==NR{a[\$1]++;next} {if (a[\$1] > 1) print \$2, \$3}' ./NM_\${filename}_tmp.txt ./NM_\${filename}_tmp.txt > ${output_novoalign}/NM_paired_\$filename.txt
	wc -l ${output_novoalign}/NM_paired_\$filename.txt > ${output_novoalign}/NM_paired.number
	rm NM_\${filename}_tmp.txt
	rm ${output_novoalign}/NM_\$filename.txt
	awk '{print \">\"\$1\"\n\"\$2}' ${output_novoalign}/NM_paired_\$filename.txt > ${output_novoalign}/NM_paired_\$filename.fasta


    fi
done
" >> $script



if [[ ! "$local" == "interactive" ]]; then
    echo $local
    qsub -cwd  -o cluster/out -e cluster/error -q $local $script

fi

fi

############## end of the STEP1 






########################################## STEP2  blastn against host - optional step (not necessary for serum data)

if [[ "$step2_q1" == "TRUE" ]]; then


    echo -e "6) Submit blastn job against human reference"

    if [[ "$merged" == "TRUE" ]]; then

	blastn_input_files="${output_novoalign}/NM_${sample}_overlapping.fasta  ${output_novoalign}/NM_paired_${sample}_nonOverlapping.fasta"
        echo "Input files for blastn are in  '$blastn_input_files'"
       

    else
        
        blastn_input_files="${output_novoalign}/NM_paired_${sample}.fasta"
        echo "Input files for blastn are in  '$blastn_input_files'"
    fi
   
	
    for i in $blastn_input_files; do


    ls -lh $i
    if [ ! -e "$i" ]; then 
	echo "Error, input file for blastn $i does not exist"    ##########Check input for blastn (created in previous step) exists
	exit
    

    else

	filename=`basename $i .fasta`
	outputblastn=${output_blastn}/$filename.ncbiBLASTn
	echo $i
	echo $filename	
	echo $output

	echo "
$blastn -db $db -query  $i  -outfmt \"6 qacc sacc evalue pident qstart qend sstart send\"  -num_alignments 1   -evalue 0.1  -culling_limit 1 -num_threads 12  > $outputblastn
" >> $script
	
 fi
    done





    echo -e "7) filter out blastn hits and keep filtered dataset"

    echo "

blastnfiles="${output_blastn}/*.ncbiBLASTn"

for i in \$blastnfiles
   do
   filename=\`basename \$i .ncbiBLASTn\`
       echo \$i
        echo \$filename
	if [[ \$i == *_overlapping* ]]; then
####### Make filtered files for merged reads (single end)

            echo \$i

            initialNM=${output_novoalign}/NM_${sample}_overlapping.txt
            filteredNM=${output_blastn}/\${filename}_filtered.txt
            echo \$initialNM
            echo \$filteredNM
            awk -F\"\\t\" 'BEGIN {OFS=\"\\t\"} NR==FNR{a[\$1]=\$1;next} a[\$1]!=\$1{print \$1, \$2}' \${i} \${initialNM} > \${filteredNM}
	    wc -l \${filteredNM} > ${output_blastn}/NM_single.number

        else

####### Make fasta files for non overlapping reads (paired end)
            echo \$i

            file1=\${i}
            file1tmp=${output_blastn}/\${filename}_ncbi_tmp.txt


	    if [[ "$merged" == "TRUE" ]]; then

        	    file2=${output_novoalign}/NM_paired_${sample}_nonOverlapping.txt
            	    file2tmp=${output_blastn}/NM_paired_${sample}_nonOverlapping_tmp.txt
	  else
		   file2=${output_novoalign}/NM_paired_${sample}.txt
                    file2tmp=${output_blastn}/NM_paired_${sample}_tmp.txt

	fi
            filtered=${output_blastn}/\${filename}_filtered.txt

            awk -F\"\\t\" '{split(\$1, a, \"/\");  print a[1], \$1, \$3}' \${file1} | uniq > \${file1tmp}
            awk -F\"\\t\" '{split(\$1, a, \"/\");  print a[1], \$1, \$2}' \${file2} | uniq > \${file2tmp}

            echo \$file1tmp
            echo \$file2tmp

                                                   
            awk -F\" \" 'BEGIN {OFS=\"\\t\"} NR==FNR{a[\$1]=\$1;next} a[\$1]!=\$1{print \$2,\$3}' \${file1tmp} \${file2tmp} > \${filtered}
            wc -l \${filtered} > ${output_blastn}/NM_paired.number


            rm \${file1tmp}
            rm \${file2tmp}

        fi

    done

" >> $script                         


    if [[ ! "$local" == "interactive" ]]; then
	qsub -cwd  -o cluster/out -e cluster/error -q $local $script

    fi


fi


########### end of STEP2



############################################################## STEP3 blastx submitted on  queue14

if [[ "$step3_q14" == "TRUE" ]]; then

    echo -e "8) Submit blastx jobs against viral database"

    if [ ! -e $dbViral ]; then echo "File $dbViral does not exist."; exit; fi
    

    if [[ "$merged" == "TRUE" ]]; then    
	if [[ "$blastnDone" == "TRUE" ]]; then    				########## use filtered datasets

		blastx_input_files="${output_blastn}/NM_${sample}_overlapping_filtered.txt ${output_blastn}/NM_paired_${sample}_nonOverlapping_filtered.txt"
		echo "Input files for blastx are in '$blastx_input_files'"
	
	else 									######### use datasets from novoalign
	 
	       blastx_input_files="${output_novoalign}/NM_${sample}_overlapping.txt  ${output_novoalign}/NM_paired_${sample}_nonOverlapping.txt"
		echo "Input files for blastx are in  '$blastx_input_files'"
  	fi


   else   

	if [[ "$blastnDone" == "TRUE" ]]; then
		blastx_input_files="${output_blastn}/NM_paired_${sample}_filtered.txt"
	else 
		blastx_input_files="${output_novoalign}/NM_paired_${sample}.txt"
		echo "Input files for blastx are in  '$blastx_input_files'"
  	fi

   fi
    
    
    for i in $blastx_input_files; do

	ls -lh $i
	if [ ! -e "$i" ]; then 
	    echo "Error, input file for blastx $i does not exist"    ##########Check that input for blastx (created in previous step) exists
	    exit
    

	else
	
	filename=`basename $i .txt`
	
	if [[ $i =~ .*_paired.* ]]; then   ################## if the file consists of paired reads
	    
	    if [[ "$blastnDone" == "TRUE" ]]; then
		numBlastxJobs=`awk '{print $1/10000}' ${output_blastn}/NM_paired.number | awk -F"." '{print \$1}'`
	    else
	    	numBlastxJobs=`awk '{print $1/10000}' ${output_novoalign}/NM_paired.number | awk -F"." '{print \$1}'`
	    fi	    
	    
	    goodNum=$(( $numBlastxJobs + 1 ))
	    echo "Non merged reads for blastx are in $i and number of jobs $goodNum"
	    
	    for Estart in `seq 0 $numBlastxJobs`; do				
		((start=Estart*10000))
		((end=start+10000))
		echo $start $end
		
		blastxScript=cluster/submission/blastx_${filename}_$start.sh
		echo $blastxScript
		
		echo "
#!/bin/bash
#$ -S /bin/bash

export PATH=\${PATH}:${Software}/blast-2.2.24/bin
export PERL5LIB=\${PERL5LIB}:${Software}/bioperl-live

perl $perlBlastx  $i ${output} $filename  $start $end $dbViral

" > $blastxScript
		qsub -cwd  -o cluster/out -e cluster/error -q queue14 $blastxScript
	  
		echo "sub script: $blastxScript"
	    done
	    
	    
	else    ##############################that is for single end reads
          
	    goodNum=$(($numBlastxJobs + 1))
	    echo "Merged reads for blastx are in $i and number of jobs $goodNum"
	    
	    if [[ "$blastnDone" == "TRUE" ]]; then
                numBlastxJobs=`awk '{print $1/10000}' ${output_blastn}/NM_single.number | awk -F"." '{print \$1}'`
		
	    else
	    	numBlastxJobs=`awk '{print $1/10000}' ${output_novoalign}/NM.number | awk -F"." '{print \$1}'`
	    fi
	    
	    for Estart in `seq 0 $numBlastxJobs`; do
		
		((start=Estart*10000))
		((end=start+10000))
		echo $start $end
		
		blastxScript=cluster/submission/blastx_${filename}_$start.sh
		
		echo "
#!/bin/bash
#$ -S /bin/bash

export PATH=\${PATH}:${Software}/blast-2.2.24/bin
export PERL5LIB=\${PERL5LIB}:${Software}/bioperl-live

perl $perlBlastx  $i ${output} $filename  $start $end $dbViral

 " >  $blastxScript
		      echo "sub script: $blastxScript"
		      qsub -cwd  -o cluster/out -e cluster/error -q queue14 $blastxScript
		  done	    

	fi
	fi	
    done
fi

######################################## end of STEP3




###################################################### STEP4 with queue1-Velvet

if [[ "$step4_q1" == "TRUE" ]]; then
    echo -e "9) Take viral reads and make fasta file for Velvet."


    blastxfiles="${output_subsetted}/*.txt"
    echo " Blastx files are $blastxfiles"

    ########## start by cleaning up these files if they exist
    concatBlastOver="${output_blastx}/NM_${sample}_overlapping_vs_viral.txt"
    concatBlastNon="${output_blastx}/NM_${sample}_nonOverlapping_vs_viral.txt"
    for file in $concatBlastOver $concatBlastNon; do
	if [ -e $file ]; then rm $file; fi
    done

    for i in $blastxfiles;
    do

	ls -lh $i
	if [ ! -e "$i" ]; then 
	    echo "Error,  blastx output files $i do not exist"    ##########Check that blastx output files (created in previous step) exist
	    exit
    

	else
	    
	    echo $i
	    if [[ $i == *_overlapping* ]]; then
		cat $i >>  $concatBlastOver
	    else
		cat $i >> $concatBlastNon
	    fi
	fi
    done
    
    concatBlastx="${output_blastx}/*.txt"
    for i in $concatBlastx;
      do
	filename=`basename \$i .txt`	

	if [[ $i == *_overlapping* ]]; then
####### Make fasta files for merged reads (single end)

	    echo $i
	    
	    singletmp=${output_velvet_input}/velvet_input_single.txt
	    velvetInputSingle=${output_velvet_input}/velvet_input_single.fasta
	    
	    awk -F " "  '{print $1, $2}' $i | uniq >> $singletmp
	    awk -F " "  '{ print ">"$1"\n"$2}' $singletmp | uniq >> $velvetInputSingle

	    rm $singletmp

	else
	    
####### Make fasta files for non overlapping reads (paired end)
	    echo $i

	    file1=${i}
	    file1tmp=${output_velvet_input}/${filename}_tmp.txt
	  
	  if [[ "$merged" == "TRUE" ]]; then
	 	 file2=${output_novoalign}/NM_paired_${sample}_nonOverlapping.txt
	   	 file2tmp=${output_velvet_input}/NM_paired_${sample}_nonOverlapping_tmp.txt
	  else
		 file2=${output_novoalign}/NM_paired_${sample}.txt
                 file2tmp=${output_velvet_input}/NM_paired_${sample}_tmp.txt

	  fi	  
  		velvetInputPaired=${output_velvet_input}/velvet_input_paired.fasta
	    
	    awk -F"\t" '{split($1, a, "/");  print a[1], $1, $3}' $file1 | uniq > $file1tmp
	    awk -F"\t" '{split($1, a, "/");  print a[1], $1, $2}' $file2 | uniq > $file2tmp

	    echo $file1tmp
	    echo $file2tmp

	    awk -F" " ' NR==FNR{a[$1]=$1;next} a[$1]==$1{print ">"$2"\n"$3}' $file1tmp $file2tmp > $velvetInputPaired
	    
	    rm $file1tmp
	    rm $file2tmp

	fi

    done

    echo -e "10) Velvet. Try several parameters."
  
    velvetInputFiles="${output_velvet}/*.fasta"
    echo " Velvet Input files are $velvetInputFiles"

    if [[ "$merged" == "TRUE" ]]; then
    
	velvetInputFiles="${velvetInputSingle} ${velvetInputPaired}"
	echo "Input files for velvet are in  '$velvetInputFiles'"

        
	for id in `seq 15 2 51`;
	do

	    outdir=${output_velvet}/output_k$id/

	    echo $outdir

	    echo "
${velveth}  $outdir  $id -fasta -shortPaired $velvetInputPaired -short $velvetInputSingle

" >> $script

	done
	
    else

	velvetInputFiles="$velvetInputPaired"
	echo "Input files for velvet are in  '$velvetInputFiles'"

    
	for id in `seq 15 2 51`;
	do

	    outdir=${output_velvet}/output_k$id/

	    echo $outdir

	    echo "
${velveth}  $outdir  $id -fasta -shortPaired $velvetInputPaired 
" >> $script

	done

    fi


    for id in `seq 15 2 51` ;
    do

	dir=${output_velvet}/output_k$id

	echo "
${velvetg} $dir  -read_trkg yes -amos_file yes -unused_reads yes -exp_cov auto

" >> $script

    done



if [[ ! "$local" == "interactive" ]]; then
	qsub -cwd  -o cluster/out -e cluster/error -q $local $script
    fi


fi

############# end of STEP4




################################################# STEP5 - Extract longest contigs to blastx against nr
if [[ "$step5_q1" == "TRUE" ]]; then

    echo -e "11) Extract contigs greater than 150bp for k that has longest contig (top 3)."
    
    grep 'Final graph' ${output_velvet}/output_k*/Log | sort  -k 11,11n | tail -3 > ${output_velvet}/longContigs.txt

    awk -F"," '{print $1}'  ${output_velvet}/longContigs.txt | sed -e 's/.*_k/k/g' | sed -e 's/\/.*//g' > ${output_velvet}/kmer_params.txt

    for k in `cat ${output_velvet}/kmer_params.txt`; do 

	inputContigs=${output_velvet}/output_$k/contigs.fa

		echo $k
		echo "Extract Long contigs from  $inputContigs"
		
		echo "

export PERL5LIB=\${PERL5LIB}:${Software}/bioperl-live

perl $perlExtractContigs  $inputContigs ${output} $k $contigLengthCutoff
" >> $script
	    
    done

    if [[ ! "$local" == "interactive" ]]; then
	qsub -cwd  -o cluster/out -e cluster/error -q $local $script
    fi

	       
fi

################# end of STEP5


################################################# STEP6: Blastx against nr with queue14
if [[ "$step6_q14" == "TRUE" ]]; then

    
    if [ ! -e $dbnr ]; then echo "File $dbnr does not exist."; exit; fi

    echo -e "12) Blastx contigs against nr"

    for k in `cat ${output_velvet}/kmer_params.txt`; do 
          
        contigs_input="${output_velvet}/output${k}_contigs_grt140.txt"
        echo "Input files for blastx are in  '$contigs_input'"
	

        for i in $contigs_input; do

	    ls -lh $i
	    if [ ! -e "$i" ]; then 
		echo "Error, input contigs for blastx against nr $i do not exist"    ##########Check that input for blastx (created in previous step) exist
		exit
    

	    else
	
		filename=`basename $i .txt`
		wc -l $i > ${output_velvet}/${filename}.number	

	
		numBlastxJobs=`awk '{print $1/2}' ${output_velvet}/${filename}.number | awk -F"." '{print \$1}'`
		
		goodNum=$(( $numBlastxJobs + 1 ))
		echo "Contigs for blastx against nr are in $i and number of jobs $goodNum"
	    
		for Estart in `seq 0 $numBlastxJobs`; do				
		    ((start=Estart*2))
		    ((end=start+2))
		    echo $start $end
		
		    blastxContigs=cluster/submission/blastx_${filename}_$start.sh
		    echo $blastxContigs
		
		    echo "
#!/bin/bash
#$ -S /bin/bash

export PATH=\${PATH}:${Software}/blast-2.2.24/bin
export PERL5LIB=\${PERL5LIB}:${Software}/bioperl-live

perl $perlBlastxContigs  $i ${output} $k  $start $end  $dbnr

" > $blastxContigs
		qsub -cwd  -o cluster/out -e cluster/error -q queue14 $blastxContigs
		
		echo "sub script: $blastxContigs"
		done
	    fi
	done
    done	 

fi

######### end of STEP6

######################################################### STEP7 - find viral contigs
if [[ "$step7_q14" == "TRUE" ]]; then


    echo -e "13) Extract viral contigs"
    

    for k in `cat ${output_velvet}/kmer_params.txt`; do
	
	if [ -e ${output_velvet}/output${k}_contigs_vs_nr.txt ]; then rm ${output_velvet}/output${k}_contigs_vs_nr.txt; fi

        blastxfiles=${contigs_subsetted}/output${k}*.txt
        echo " Blastx-ed contigs are $blastxfiles"
        for i in $blastxfiles; do

	    ls -lh $i
	    if [ ! -e "$i" ]; then 
		echo "Error,  blastx output files $i do not exist"    ##########Check that blastx output files (created in previous step) exist
		exit
    

	    else
                         
            echo $i
            cat $i >> ${output_velvet}/output${k}_contigs_vs_nr.txt
	    fi

	done
    done
    

    for k in `cat ${output_velvet}/kmer_params.txt`; do

#####################Find top hits for each contig from all organisms

	myfile=${output_velvet}/output${k}_contigs_vs_nr.txt
	myfiletmp=${output_velvet}/output${k}_contigs_vs_nr_tmp.txt
	output=${output_velvet}/output${k}_significant.txt
	outputtmp=${output_velvet}/output${k}_significant_tmp.txt
	signifContigstmp=${output_velvet}/${k}_signifContigs_tmp.txt
	signifContigs=${output_velvet}/${k}_signifContigs.txt


	awk -F"\t" 'BEGIN {OFS = "\t"}
{
 min[$1] = !($1 in min) ? $10 : ($10 < min[$1]) ? $10 : min[$1]
  }
END {
  for (i in min){
    print i,min[i]
}
}' $myfile > $output   


	awk -F"\t" 'BEGIN { OFS="\t" } {print $1"_"$2, $0}' $output > $outputtmp
	awk -F"\t" 'BEGIN { OFS="\t" } {print $1"_"$10, $0}' $myfile > $myfiletmp

	awk -F"\t" 'BEGIN {OFS="\t"} NR==FNR{a[$1]=$1;next} a[$1]==$1{print $2, $6, $11}' $outputtmp $myfiletmp | sort | uniq | awk -F"\t" 'BEGIN {OFS="\t"} {split($1, a, "_"); print $1, a[4],$2, $3}' > $signifContigstmp            

	rm $outputtmp
	rm $myfiletmp
       


	awk -F"\t" 'BEGIN {OFS="\t"} NR==0{print;next} {a[$1]=$2; b[$1]=b[$1] sep[$1] $3; c[$1]=$4; sep[$1]=","}END{for (i in a) print i, a[i], b[i], c[i]}' $signifContigstmp | sort -k 2,2 -n -r > $signifContigs



######Find top viral hits for each contig
	viralmyfile=${output_velvet}/output${k}_contigs_vs_nr_viral.txt
	viralmyfiletmp=${output_velvet}/output${k}_contigs_vs_nr_tmp_viral.txt
	viraloutput=${output_velvet}/output${k}_significant_viral.txt
	viraloutputtmp=${output_velvet}/output${k}_significant_tmp_viral.txt
	
	viralsignifContigstmp=${output_velvet}/${k}_signifContigs_tmp_viral.txt
	viralsignifContigs=${output_velvet}/${k}_signifContigs_viral.txt
	finaltable=${output_final}/${sample}_${k}contigs_final.txt

	grep virus $myfile > $viralmyfile

	awk -F"\t" 'BEGIN {OFS = "\t"}
{
 min[$1] = !($1 in min) ? $10 : ($10 < min[$1]) ? $10 : min[$1]
  }
END {
  for (i in min){
    print i,min[i]
}
}' $viralmyfile > $viraloutput


	awk -F"\t" 'BEGIN { OFS="\t" } {print $1"_"$2, $0}' $viraloutput > $viraloutputtmp
	awk -F"\t" 'BEGIN { OFS="\t" } {print $1"_"$10, $0}' $viralmyfile > $viralmyfiletmp

	awk -F"\t" 'BEGIN {OFS="\t"} NR==FNR{a[$1]=$1;next} a[$1]==$1{print $2, $6, $11}' $viraloutputtmp $viralmyfiletmp |  sort | uniq | awk -F"\t" 'BEGIN {OFS="\t"} {split($1, a, "_"); print $1, a[4],$2, $3}' > $viralsignifContigstmp
	rm $viraloutputtmp
	rm $viralmyfiletmp



	awk -F"\t" 'BEGIN {OFS="\t"} NR==0{print;next} {a[$1]=$2; b[$1]=b[$1] sep[$1] $3; c[$1]=$4; sep[$1]=","}END{for (i in a) print i, a[i], b[i], c[i]}' $viralsignifContigstmp | sort -k 2,2 -n -r > $viralsignifContigs



	awk -F"\t" 'BEGIN {OFS="\t"} NR==FNR{a[$1]=$0;next}{if (a[$1]) printf a[$1]"\t"; else printf "NA\tNA\tNA\tNA\t"}1' $viralsignifContigs $signifContigs | awk -F"\t" 'BEGIN {OFS="\t"} {print $5, $6, $7, $8, $3, $4}' > $finaltable
    
	rm $viralsignifContigstmp
	rm $signifContigstmp

    done
    
    
fi
