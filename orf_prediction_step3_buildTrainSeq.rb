#=== config

$blastout = "good_orf_candidates.pep.vs.RefSeq_Ath_Osa.pep.blastp.fmt7c.txt"
$cdsf = "good_orf_candidates.cds"
$pepf = $cdsf.sub(/\.cds$/, ".pep")

#===

$scriptdir = File.dirname(__FILE__)

### select reliable models based on blastp result

blast_passed = "#{$blastout}.passed"
blast_passed_ids = "#{blast_passed}.ids"
cmd = "ruby #{$scriptdir}/select_train_models_based_on_blastp_results.rb #{$blastout} > #{blast_passed}"
puts cmd
system cmd

cmd = "cut -f 1 #{blast_passed} > #{blast_passed_ids}"
puts cmd
system cmd

### Select good ORFs for next round training

fasta = $cdsf
idlist = blast_passed_ids
outfasta = "orfs_for_round2_train_pre.cds"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{outfasta}"
puts cmd
system cmd

fasta = $pepf
outfasta = "orfs_for_round2_train_pre.pep"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{outfasta}"
puts cmd
system cmd


###  merge similar sequences
###    >90% identical seqs are merged
input = "orfs_for_round2_train_pre.pep"
output = "#{input}.cdhitest90"
cmd = "cd-hit -i #{input} -c 0.9 -G 1 -g 1 -T 6 -M 0 -d 0 -o #{output}"
puts cmd
system cmd

file1 = output
file2 = "orfs_for_round2_train.pep"
cmd = "cp #{file1} #{file2}"
puts cmd
system cmd

cmd = "fast ids #{file2} > #{file2}.ids"
puts cmd
system cmd

fasta = "orfs_for_round2_train_pre.cds"
idlist = "#{file2}.ids"
outfasta = "orfs_for_round2_train.cds"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb  #{fasta} #{idlist} > #{outfasta}"
puts cmd
system cmd

cds_for_train2 = outfasta


