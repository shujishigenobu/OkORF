#!/bin/sh

QUERY=$1
DB=$2
OUTF=`basename $QUERY`.vs.`basename $DB`.blastp.fmt7c.txt

NCPU=$3
EVALUE=$4

FORMAT="7 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen"
 
blastp -query $QUERY \
 -db  $DB \
 -evalue $EVALUE \
 -num_threads $NCPU \
 -soft_masking yes  \
 -seg yes \
 -outfmt "$FORMAT" \
 -max_target_seqs 10 \
 -out $OUTF \

 touch $OUTF.finished
