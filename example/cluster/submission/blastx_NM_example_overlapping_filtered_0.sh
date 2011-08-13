
#!/bin/sh
#$ -S /bin/sh

export PATH=${PATH}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/blast-2.2.24/bin
export PERL5LIB=${PERL5LIB}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/bioperl-live

perl /ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/scripts/NM_blastx.pl  results/blastn/NM_example_overlapping_filtered.txt results NM_example_overlapping_filtered  0 10000 /ugi/data/vincent/sequence_database/viral/viral.protein.faa

 
