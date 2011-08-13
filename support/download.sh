
###################### 1000 Genomes dataset
wget ftp://ftp.sanger.ac.uk/pub/1000genomes/tk2/main_project_reference/human_g1k_v37.fasta.gz


##Command line to create the novoalign index
##$novoindex  -k 15 -s 2 hg19.k15.s2.novoindex  ${fastaFile}


################ Viral protein databases
wget ftp://ftp.ncbi.nih.gov/refseq/release/viral/viral1.protein.faa.gz
wget ftp://ftp.ncbi.nih.gov/refseq/release/viral/viral2.protein.faa.gz

########### nr database
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz



