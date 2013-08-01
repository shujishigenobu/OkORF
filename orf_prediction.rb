$scriptdir = "transdecoder_mod"

### first round prediction

$transcript_file = "Trinity_pame2_130109p1.fasta"
$num_top_longORFs_for_train = 500

### Capture ALL ORFs

outprefix = "predicted_orfs"
cmd = "perl #{$scriptdir}/capture_all_ORFs.pl #{$transcript_file} #{outprefix}"
puts cmd

#system(cmd)

# outputs : predicted_orfs.pep, predicted_orfs.gff3, predicted_orfs.cds


### Remove redundancy

input = "predicted_orfs.cds"
output = "#{input}.rmdup"
cmd = "ruby #{$scriptdir}/remove_duplicates_in_fastaf.rb #{input} > #{output}"
puts cmd 

# system(cmd)

idlist = "#{output}.ids"
cmd = "fast ids #{output} > #{idlist}"
puts cmd
#system cmd

fasta = "predicted_orfs.pep"
output = "#{fasta}.rmdup"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{output}"
puts cmd
#system cmd

input_gff = "predicted_orfs.gff3"
output_gff = "#{input_gff}.rmdup"
cmd = "ruby #{$scriptdir}/get_gff_entries_from_idlist.rb #{input_gff} #{idlist} > #{output_gff}"
puts cmd
#system cmd

### Get longest entries for training

cds = "predicted_orfs.cds.rmdup"
ntop = $num_top_longORFs_for_train
out = "#{cds}.longest#{ntop}.fa"

cmd = "#{$scriptdir}/util/get_top_longest_fasta_entries.pl #{cds} #{ntop} >#{out}"
puts cmd
#system cmd

cds_for_train = out

### Calculate base prob

input = $transcript_file
output = "#{input}.base_freqs.dat"

cmd = "#{$scriptdir}/util/compute_base_probs.pl #{input} > #{output}"

puts cmd
#system cmd

basefreqf = output

### Calculate hexamer scores from training sequences

cds_for_train
output = "#{cds_for_train}.hexamer.scores"

cmd = "#{$scriptdir}/util/seq_n_baseprobs_to_logliklihood_vals.pl #{cds_for_train} #{basefreqf} > #{output}"
puts cmd
#system cmd

hexscore = output

### Score all cds entries
cdsf = "predicted_orfs.cds.rmdup"
hexscore
output = "#{cdsf}.scores"

cmd = "#{$scriptdir}/util/score_CDS_liklihood_all_6_frames.pl #{cdsf} #{hexscore} > #{output}"
puts cmd
#system cmd

markov_score_f = output

### Select good ORFs based on markov score and length

cdsf
markov_score_f
output = "#{cdsf}.selected"

cmd = "ruby #{$scriptdir}/select_good_orfs_based_on_markovscore_and_length.rb #{cdsf} #{markov_score_f} > #{output}"
puts cmd
#system cmd

ids_passed = "#{output}.ids"
cmd = "cut -f 1 #{output} > #{ids_passed}"
puts cmd
#system cmd

### Get good ORF entries reading the id list above

gfff = "predicted_orfs.gff3.rmdup"
cmd = "#{$scriptdir}/util/index_gff3_files_by_isoform.pl #{gfff}"
puts cmd
#system cmd

output = "good_orf_candidates.gff3"
cmd = "#{$scriptdir}/util/gene_list_to_gff.pl #{ids_passed} #{gfff}.inx > #{output}"
puts cmd
#system cmd
gfff = output


bedf = gfff.sub(/gff3$/, "bed")
cmd = "#{$scriptdir}/util/gff3_file_to_bed.pl #{gfff} > #{bedf}"
puts cmd
#system cmd

pepf = gfff.sub(/gff3$/, "pep")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{$transcript_file}> #{pepf}"
puts cmd
#system cmd

cdsf = gfff.sub(/gff3$/, "cds")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{$transcript_file} CDS > #{cdsf}"
puts cmd
#system cmd


### BLASTP against refseq

blastdb = "/home/DB/local/arth_refseq7_90/arth_refseq7.cdhit90.pep"
ncpu = 6
evalue = 1.0e-8

cmd = "sh #{$scriptdir}/run_blastp.sh #{pepf} #{blastdb} #{ncpu} #{evalue}"
puts cmd
# system cmd
blastout = "#{File.basename(pepf)}.vs.#{File.basename(blastdb)}.blastp.fmt7c.txt"

blast_passed = "#{blastout}.passed"
blast_passed_ids = "#{blast_passed}.ids"
cmd = "ruby #{$scriptdir}/select_train_models_based_on_blastp_results.rb #{blastout} > #{blast_passed}"
puts cmd
#system cmd

cmd = "cut -f 1 #{blast_passed} > #{blast_passed_ids}"
puts cmd
#system cmd

### Select good ORFs for next round training

fasta = cdsf
idlist = blast_passed_ids
outfasta = "orfs_for_round2_train_pre.cds"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{outfasta}"
puts cmd
#system cmd

fasta = pepf
outfasta = "orfs_for_round2_train_pre.pep"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{outfasta}"
puts cmd
#system cmd


###  merge similar sequences
input = "orfs_for_round2_train_pre.pep"
output = "#{input}.cdhitest90"
cmd = "cd-hit -i #{input} -c 0.9 -G 1 -g 1 -T 6 -M 0 -d 0 -o #{output}"
puts cmd
#system cmd

file1 = output
file2 = "orfs_for_round2_train.pep"
cmd = "cp #{file1} #{file2}"
puts cmd
#system cmd

cmd = "fast ids #{file2} > #{file2}.ids"
puts cmd
#system cmd

fasta = "orfs_for_round2_train_pre.cds"
idlist = "#{file2}.ids"
outfasta = "orfs_for_round2_train.cds"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb  #{fasta} #{idlist} > #{outfasta}"
puts cmd
#system cmd

cds_for_train2 = outfasta


### Capture ALL ORFs (2nd)

$min_len = 50 #aa
#$len_retain_long_orfs = 450 #bp

outprefix = "predicted2_orfs"
cmd = "perl #{$scriptdir}/capture_all_ORFs.pl #{$transcript_file} #{outprefix} #{$min_len}"
puts cmd
system(cmd)

### Remove redundancy 

input = "predicted2_orfs.cds"
output = "#{input}.rmdup"
cmd = "ruby #{$scriptdir}/remove_duplicates_in_fastaf.rb #{input} > #{output}"
puts cmd 

system(cmd)

idlist = "#{output}.ids"
cmd = "fast ids #{output} > #{idlist}"
puts cmd
system cmd

fasta = "predicted2_orfs.pep"
output = "#{fasta}.rmdup"
cmd = "ruby #{$scriptdir}/get_fasta_entries_from_idlist.rb #{fasta} #{idlist} > #{output}"
puts cmd
system cmd

input_gff = "predicted2_orfs.gff3"
output_gff = "#{input_gff}.rmdup"
cmd = "ruby #{$scriptdir}/get_gff_entries_from_idlist.rb #{input_gff} #{idlist} > #{output_gff}"
puts cmd
system cmd

### Calculate base prob
# reuse 1st round data

basefreqf

### Calculate hexamer scores from training sequences

cds_for_train = cds_for_train2
output = "#{cds_for_train}.hexamer.scores"

cmd = "#{$scriptdir}/util/seq_n_baseprobs_to_logliklihood_vals.pl #{cds_for_train} #{basefreqf} > #{output}"
puts cmd
system cmd

hexscore = output


### Score all cds entries
cdsf = "predicted2_orfs.cds.rmdup"
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

gfff = "predicted2_orfs.gff3.rmdup"
cmd = "#{$scriptdir}/util/index_gff3_files_by_isoform.pl #{gfff}"
puts cmd
system cmd

output = "good_orf_candidates2.gff3"
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

### exclude sharow orfs

output = gfff.sub(/gff3/, "eclipsed_orfs_removed.gff3")
cmd = "#{$scriptdir}/util/remove_eclipsed_ORFs.pl #{gfff} > #{output}"
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
