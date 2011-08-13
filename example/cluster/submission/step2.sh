
#!/bin/sh
#$ -S /bin/sh

date ##to measure the duration




/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/ncbi-blast-2.2.24+/bin/blastn -db /ugi/data/vincent/sequence_database/human_genomic/human_genomic -query  results/novoalign/NM_example_overlapping.fasta  -outfmt "6 qacc sacc evalue pident qstart qend sstart send"  -num_alignments 1   -evalue 0.1  -culling_limit 1 -num_threads 12  > results/blastn/NM_example_overlapping.ncbiBLASTn


/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/ncbi-blast-2.2.24+/bin/blastn -db /ugi/data/vincent/sequence_database/human_genomic/human_genomic -query  results/novoalign/NM_paired_example_nonOverlapping.fasta  -outfmt "6 qacc sacc evalue pident qstart qend sstart send"  -num_alignments 1   -evalue 0.1  -culling_limit 1 -num_threads 12  > results/blastn/NM_paired_example_nonOverlapping.ncbiBLASTn



blastnfiles=results/blastn/*.ncbiBLASTn

for i in $blastnfiles
   do
   filename=`basename $i .ncbiBLASTn`
       echo $i
        echo $filename
	if [[ $i == *_overlapping* ]]; then
####### Make filtered files for merged reads (single end)

            echo $i

            initialNM=results/novoalign/NM_example_overlapping.txt
            filteredNM=results/blastn/${filename}_filtered.txt
            echo $initialNM
            echo $filteredNM
            awk -F"\t" 'BEGIN {OFS="\t"} NR==FNR{a[$1]=$1;next} a[$1]!=$1{print $1, $2}' ${i} ${initialNM} > ${filteredNM}
	    wc -l ${filteredNM} > results/blastn/NM_single.number

        else

####### Make fasta files for non overlapping reads (paired end)
            echo $i

            file1=${i}
            file1tmp=results/blastn/${filename}_ncbi_tmp.txt


	    if [[ TRUE == TRUE ]]; then

        	    file2=results/novoalign/NM_paired_example_nonOverlapping.txt
            	    file2tmp=results/blastn/NM_paired_example_nonOverlapping_tmp.txt
	  else
		   file2=results/novoalign/NM_paired_example.txt
                    file2tmp=results/blastn/NM_paired_example_tmp.txt

	fi
            filtered=results/blastn/${filename}_filtered.txt

            awk -F"\t" '{split($1, a, "/");  print a[1], $1, $3}' ${file1} | uniq > ${file1tmp}
            awk -F"\t" '{split($1, a, "/");  print a[1], $1, $2}' ${file2} | uniq > ${file2tmp}

            echo $file1tmp
            echo $file2tmp

                                                   
            awk -F" " 'BEGIN {OFS="\t"} NR==FNR{a[$1]=$1;next} a[$1]!=$1{print $2,$3}' ${file1tmp} ${file2tmp} > ${filtered}
            wc -l ${filtered} > results/blastn/NM_paired.number


            rm ${file1tmp}
            rm ${file2tmp}

        fi

    done


