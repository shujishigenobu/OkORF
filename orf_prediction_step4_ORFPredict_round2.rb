#=== config
# $transcript_file = "Trinity_Mono_130215.fasta"
# $min_len = 50 #aa
# $len_retain_long_orfs = 900 #bp
# $basefreqf = "#{$transcript_file}.base_freqs.dat"
# $cds_for_train = "orfs_for_round2_train.cds"
#===

### Parse command-line options
require 'optparse'
opt = OptionParser.new
opt.on('-t', '--transcript FASTA', 'transcript file to search ORFs (in fasta format) [required]') {|v|
  $transcript_file = v}
opt.on('-m', '--min [MIN_LEN]', 'min aa length to predict [default:50]') {|v| $min_len = v.to_i}
opt.on('-b', '--basefreq FILE', 'base frequence file gerenated by previous round of prediction [required]'){|v|
  $basefreqf = v}
opt.on('-n', '--cdstrain FASTA', 'cds for training in FASTA format [required]'){|v| $cds_for_train = v}
opt.on('-r', '--retainlen [LENGTH]', 'length to retain long ORFs (bp) [default:900]'){|v| $len_retain_long_orfs = v.to_i}
opt.on('-h', '--help', 'show this message'){
  puts opt; exit
}

opt.parse!(ARGV)
unless $transcript_file || $basefreq || $cds_for_train
  raise "\nError: Required option missing.\n"
end

$min_len = 50 unless $min_len
$len_retain_len_orfs = 900 unless $len_retain_len_orfs

$scriptdir = File.dirname(__FILE__)

### Capture ALL ORFs (2nd)


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

basefreqf = $basefreqf
unless File.exist?(basefreqf)
  raise "\nERROR: #{basefreqf} not found\n"
end

### Calculate hexamer scores from training sequences

cds_for_train = $cds_for_train
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
