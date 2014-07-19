#!/bin/sh
#$ -S /bin/bash
#$ -cwd
 
QUERY=$1

IDENT=0.97
OUTF=`basename $QUERY .fa`.cdest"${IDENT/./}".aS90aL90.fa

echo  $OUTF

cd-hit-est \
-i $QUERY \
-c $IDENT \
-G 1 \
-g 1 \
-aS 0.9 -aL 0.9 \
-r 0 \
-T 8 -M 0 \
-d 0 \
-o $OUTF