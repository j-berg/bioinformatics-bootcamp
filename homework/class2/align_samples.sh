#!/bin/bash
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH -o /uufs/chpc.utah.edu/common/home/uNID/slurmjob-%j
#SBATCH --partition=notchpeak
source /uufs/chpc.utah.edu/common/home/uNID/miniconda3/etc/profile.d/conda.sh
source activate class
# Initialize output directory
SCRDIR=/scratch/general/lustre/$USER/$SLURM_JOBID
mkdir -p $SCRDIR
INPUT=/uufs/chpc.utah.edu/common/home/uNID/seq_files
REF=/scratch/general/lustre/uNID/yeast_index
GTF=$REF/Saccharomyces_cerevisiae.R64-1-1.100.gtf
FILES=(SRR1166442 SRR1166443 SRR1166444 SRR1166445 SRR1166446 SRR1166447)
OUTPUT=/uufs/chpc.utah.edu/common/home/uNID/seq_output
# Move raw data
mkdir -p $SCRDIR/input
mkdir -p $SCRDIR/output
# Organize output
mkdir -p $SCRDIR/output/preprocess
mkdir -p $SCRDIR/output/alignment
mkdir -p $SCRDIR/output/postprocess
mkdir -p $SCRDIR/output/count
mkdir -p $SCRDIR/output/qc
mkdir -p $OUTPUT
cd $SCRDIR/.
# Loop through all files
for FILE in ${FILES[@]}; do
        echo "Processing ${FILE}"
        prefetch ${FILE} -o $SCRDIR/input/${FILE}.sra
        fastq-dump --outdir $SCRDIR/input --split-files $SCRDIR/input/${FILE}.sra
        mv $SCRDIR/input/${FILE}_1.fastq $SCRDIR/input/${FILE}.fastq
        echo "Preprocessing..."
        # Preprocess
        fastp --thread 20 -l 30 -q 28 \
                -a TGGAATTCTCGGGTGCCAAGG \
                -i $SCRDIR/input/${FILE}.fastq \
                -o $SCRDIR/output/preprocess/${FILE}.fastq \
                -j $SCRDIR/output/preprocess/${FILE}.json \
                -h $SCRDIR/output/preprocess/${FILE}.html
        echo "Preprocessing QC..."
        # Perform quality control on pre-processed FASTQ file
        fastqc -q $SCRDIR/output/preprocess/${FILE}.fastq
        echo "Aligning..."
        # Align
        STAR --runThreadN 20 --sjdbOverhang 50 \
                --outSAMunmapped Within --outSAMtype BAM Unsorted --quantMode TranscriptomeSAM \
                --genomeDir $REF/genome \
                --sjdbGTFfile $GTF \
                --readFilesIn $SCRDIR/output/preprocess/${FILE}.fastq \
                --outFileNamePrefix $SCRDIR/output/alignment/${FILE}_ #will end in Aligned.bam
        echo "Postprocessing..."
        # Sort and Index
        samtools sort --threads 20 \
               -o $SCRDIR/output/postprocess/${FILE}_sorted.bam \
                $SCRDIR/output/alignment/${FILE}_Aligned.bam
        samtools index -@ 20 \
                $SCRDIR/output/postprocess/${FILE}_sorted.bam
        echo "Counting..."
        # Count
        htseq-count -q -f bam -m intersection-nonempty -t exon -i gene_id -r pos -s no \
                $SCRDIR/output/postprocess/${FILE}_sorted.bam \
                $GTF > $SCRDIR/output/count/${FILE}.tsv; done
# Summarize QC
multiqc $SCRDIR/output
# Clean-up
mv $SCRDIR/output/postprocess/*_sorted.bam $OUTPUT
mv $SCRDIR/output/postprocess/*_sorted.bam.bai $OUTPUT
mv $SCRDIR/output/count/*.tsv $OUTPUT
mv $SCRDIR/output/qc/*.html $OUTPUT
mv $SCRDIR/output/*.html $OUTPUT
rm -rf $SCRDIR