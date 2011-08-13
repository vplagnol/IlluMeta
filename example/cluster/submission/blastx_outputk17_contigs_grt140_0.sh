
#!/bin/sh
#$ -S /bin/sh

export PATH=${PATH}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/blast-2.2.24/bin
export PERL5LIB=${PERL5LIB}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/bioperl-live

perl /ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/scripts/blastx_Viralcontigs_nr.pl  results/velvet/outputk17_contigs_grt140.txt results k17  0 2  /ugi/home/shared/sofia/reference_seq/nr/nr.faa


