#!/bin/sh
#$ -S /bin/bash
#$ -cwd
 
QUERY=$1
OUTF=$2

IDENT=0.97

echo  $OUTF

cd-hit-est \
-i $QUERY \
-c $IDENT \
-G 0 \
-g 1 \
-aS 0.7 -aL 0.0 \
-r 0 \
-T 8 -M 0 \
-d 0 \
-o $OUTF