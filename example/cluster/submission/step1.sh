
#!/bin/bash
#$ -S /bin/bash

date ##to measure the duration





/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/fastqCollapse/fastqCollapse  -i input_files/example.1.fq.gz input_files/example.2.fq.gz -o results/collapsed/example -summary results/collapsed/example_summary.txt




/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/SHERAc/concatReads --adaptersFile ../support/adapters.fa results/collapsed/example_1.fq  results/collapsed/example_2.fq  results/merged/example




awk -F: '{if (($1~/Sequences Processed/) || ($1~/Sequences Overlapping/)) print $2}' results/merged/example.summary  | awk '{ a[$0] } END {for (i in a){for (j in a){if (i < j)  print (i/j)*100} }}' > results/percentage_merged.txt




percentage=`awk -F"." '{print $1}' results/percentage_merged.txt`

if [[ $percentage -ge 10 ]]; then
############## Hardclipping but no quality calibration
/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/novoalign -t180  -H -a  -F STDFQ -f results/merged/example.fq -d /ugi/home/shared/vincent/reference_genome/novoalign/human_g1k_v37.fasta.k15.s2.novoindex > results/novoalign/example_overlapping.novo
/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/novoalign  -t250 -H -a  -F STDFQ -f results/merged/example_single_1.fq results/merged/example_single_2.fq -d /ugi/home/shared/vincent/reference_genome/novoalign/human_g1k_v37.fasta.k15.s2.novoindex > results/novoalign/example_nonOverlapping.novo

else
############# Hardclipping and quality calibration
/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/novoalign  -t250 -H -a -k -F STDFQ -f results/collapsed/example_1.fq results/collapsed/example_2.fq -d /ugi/home/shared/vincent/reference_genome/novoalign/human_g1k_v37.fasta.k15.s2.novoindex > results/novoalign/example.novo

fi


 
novofiles=results/novoalign/*.novo
echo Novoalign files are $novofiles


for i in $novofiles
do
    echo Print $i
    filename=`basename $i .novo`
    echo Filename is $filename


    if [[ $filename == *_overlapping* ]]; then
	awk -F"\t" 'BEGIN {OFS="\t"} {if ($5~/NM/) print $1,$3}'  $i |  uniq > results/novoalign/NM_$filename.txt
	wc -l results/novoalign/NM_$filename.txt > results/novoalign/NM.number
	awk '{print ">"$1"\n"$2}' results/novoalign/NM_$filename.txt > results/novoalign/NM_$filename.fasta

    else

	awk -F"\t" '{if ($5~/NM/) print $1, $3}'  $i |  uniq > results/novoalign/NM_$filename.txt
	awk -F"\t" '{split($1, a, "/");  print a[1], $1, $2}' results/novoalign/NM_$filename.txt > NM_${filename}_tmp.txt
	awk 'BEGIN {OFS="\t"}FNR==NR{a[$1]++;next} {if (a[$1] > 1) print $2, $3}' ./NM_${filename}_tmp.txt ./NM_${filename}_tmp.txt > results/novoalign/NM_paired_$filename.txt
	wc -l results/novoalign/NM_paired_$filename.txt > results/novoalign/NM_paired.number
	rm NM_${filename}_tmp.txt
	rm results/novoalign/NM_$filename.txt
	awk '{print ">"$1"\n"$2}' results/novoalign/NM_paired_$filename.txt > results/novoalign/NM_paired_$filename.fasta


    fi
done

