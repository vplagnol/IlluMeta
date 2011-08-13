
#!/bin/sh
#$ -S /bin/sh

date ##to measure the duration





export PERL5LIB=${PERL5LIB}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/bioperl-live

perl /ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/scripts/extract_largeContigs.pl  results/velvet/output_k19/contigs.fa results k19 140



export PERL5LIB=${PERL5LIB}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/bioperl-live

perl /ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/scripts/extract_largeContigs.pl  results/velvet/output_k17/contigs.fa results k17 140



export PERL5LIB=${PERL5LIB}:/ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/exec/bioperl-live

perl /ugi/home/shared/vincent/Projects/Viral_DNA/IlluMeta/scripts/extract_largeContigs.pl  results/velvet/output_k15/contigs.fa results k15 140

