#=== conf ===

$transcript_file = "Trinity_Pran_all_130417.fa"

$num_top_longORFs_for_train = 500

#===

$scriptdir = File.dirname(__FILE__)

### Capture ALL ORFs

outprefix = "predicted_orfs"
cmd = "perl #{$scriptdir}/capture_all_ORFs.pl #{$transcript_file} #{outprefix}"
puts cmd

system(cmd)
# outputs : predicted_orfs.pep, predicted_orfs.gff3, predicted_orfs.cds

### Remove redundancy

input = "predicted_orfs.cds"
output = "#{input}.rmdup"
cmd = "ruby #{$scriptdir}/remove_duplicates_in_fastaf.rb #{input} > #{output}"
puts cmd 
system(cmd)

idlist = "#{output}.ids"
cmd = "fast ids #{output} > #{idlist}"
puts cmd
system cmd

fasta = "predicted_orfs.pep"
output = "#{fasta}.rmdup"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{output}"
puts cmd
system cmd

input_gff = "predicted_orfs.gff3"
output_gff = "#{input_gff}.rmdup"
cmd = "ruby #{$scriptdir}/get_gff_entries_from_idlist.rb #{input_gff} #{idlist} > #{output_gff}"
puts cmd
system cmd


### Get longest entries for training

cds = "predicted_orfs.cds.rmdup"
ntop = $num_top_longORFs_for_train
out = "#{cds}.longest#{ntop}.fa"

cmd = "#{$scriptdir}/util/get_top_longest_fasta_entries.pl #{cds} #{ntop} >#{out}"
puts cmd
system cmd

cds_for_train = out

### Calculate base prob

input = $transcript_file
output = "#{input}.base_freqs.dat"

cmd = "#{$scriptdir}/util/compute_base_probs.pl #{input} > #{output}"

puts cmd
system cmd

basefreqf = output

### Calculate hexamer scores from training sequences

cds_for_train
output = "#{cds_for_train}.hexamer.scores"

cmd = "#{$scriptdir}/util/seq_n_baseprobs_to_logliklihood_vals.pl #{cds_for_train} #{basefreqf} > #{output}"
puts cmd
system cmd

hexscore = output

### Score all cds entries
cdsf = "predicted_orfs.cds.rmdup"
hexscore
output = "#{cdsf}.scores"

cmd = "#{$scriptdir}/util/score_CDS_liklihood_all_6_frames.pl #{cdsf} #{hexscore} > #{output}"
puts cmd
system cmd

markov_score_f = output

### Select good ORFs based on markov score and length

cdsf
markov_score_f
output = "#{cdsf}.selected"

cmd = "ruby #{$scriptdir}/select_good_orfs_based_on_markovscore_and_length.rb #{cdsf} #{markov_score_f} > #{output}"
puts cmd
system cmd

ids_passed = "#{output}.ids"
cmd = "cut -f 1 #{output} > #{ids_passed}"
puts cmd
system cmd

### Get good ORF entries reading the id list above

gfff = "predicted_orfs.gff3.rmdup"
cmd = "#{$scriptdir}/util/index_gff3_files_by_isoform.pl #{gfff}"
puts cmd
system cmd

output = "good_orf_candidates.gff3"
cmd = "#{$scriptdir}/util/gene_list_to_gff.pl #{ids_passed} #{gfff}.inx > #{output}"
puts cmd
system cmd
gfff = output


bedf = gfff.sub(/gff3$/, "bed")
cmd = "#{$scriptdir}/util/gff3_file_to_bed.pl #{gfff} > #{bedf}"
puts cmd
system cmd

pepf = gfff.sub(/gff3$/, "pep")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{$transcript_file}> #{pepf}"
puts cmd
system cmd

cdsf = gfff.sub(/gff3$/, "cds")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{$transcript_file} CDS > #{cdsf}"
puts cmd
system cmd


