#!/bin/sh
#$ -S /bin/bash
#$ -cwd
 
QUERY=good_orf_candidates2.eclipsed_orfs_removed.cds

IDENT=0.97
OUTF=`basename $QUERY .fa`.cdest"${IDENT/./}".GaS100aL100.fa

echo  $OUTF

cd-hit-est \
-i $QUERY \
-c $IDENT \
-G 1 \
-g 1 \
-aS 1.0 -aL 1.0 \
-r 0 \
-T 8 -M 0 \
-d 0 \
-o $OUTF