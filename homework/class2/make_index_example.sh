#!/bin/bash
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH -o /uufs/chpc.utah.edu/common/home/uNID/slurmjob-%j
#SBATCH --partition=kingspeak
# Activate conda environment
source /uufs/chpc.utah.edu/common/home/uNID/miniconda3/etc/profile.d/conda.sh
source activate class
# Set variables
SCRUSER=/scratch/general/lustre/uNID
REF=/scratch/general/lustre/uNID/yeast_index
FASTA=Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa
GTF=Saccharomyces_cerevisiae.R64-1-1.100.gtf
CHR=(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI)
# initialize reference folder in scratch directory
mkdir -p $REF
cd $REF
# Download chromosome FASTA files
mkdir -p $REF/fastas
cd $REF/fastas
curl -OL ftp://ftp.ensembl.org/pub/release-100/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
gzip -d *gz
cd $REF
# Download GTF file
curl -OL ftp://ftp.ensembl.org/pub/release-100/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.100.gtf.gz
gzip -d *gz
# Generate STAR index
# Calculate --genomeSAindexNbases as:
#     min(14, log2(GenomeLength)/2 - 1)
# where GenomeLength equals total genome length of organism in bp
mkdir -p $REF/genome
STAR --runMode genomeGenerate --genomeDir $REF/genome --genomeFastaFiles $REF/fastas/$FASTA --sjdbGTFfile $REF/$GTF --runThreadN 32 --sjdbOverhang 50 --genomeSAindexNbases 11