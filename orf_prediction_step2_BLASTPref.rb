#=== conf ===
$blastdb = "RefSeq_Ath_Osa.pep"

$scriptdir = File.dirname(__FILE__)

pepf = "good_orf_candidates.pep"

### BLASTP against refseq

blastdb = $blastdb
ncpu = 8
evalue = 1.0e-8

cmd = "sh #{$scriptdir}/run_blastp.sh #{pepf} #{blastdb} #{ncpu} #{evalue}"
puts cmd
system cmd
