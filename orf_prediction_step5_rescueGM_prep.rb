require 'set'

MIN_LENGTH = 300 #bp

cds_file_before = "predicted2_orfs.cds.rmdup"
cds_file_passed = "good_orf_candidates2.eclipsed_orfs_removed.cds"
candidate_ids_f = "rescued_candidates_#{MIN_LENGTH}.ids"
transcriptf = ARGV[0]

$scriptdir = File.dirname(__FILE__)

### Make the list of gene models dropped in the previous gene finding
### Genes > MIN_LENGTH will be listed.

names_before = Set.new
File.open(cds_file_before).each do |l|
  if m =  /^>(.+?)\s/.match(l)
    name = m[1]
    names_before << name
  end
end

names_passed = Set.new
File.open(cds_file_passed).each do |l|
  if m =  /^>(.+?)\s/.match(l)
    name = m[1]
    names_passed << name
  end
end

STDERR.puts names_before.size
STDERR.puts names_passed.size

names_dropped = names_before - names_passed
STDERR.puts names_dropped.size

require 'bio'

o = File.open(candidate_ids_f, "w")
Bio::FlatFile.open(Bio::FastaFormat, cds_file_before).each do |fas|
  if names_dropped.include?(fas.entry_id) &&
      fas.seq.length >= MIN_LENGTH
    o.puts fas.entry_id
  end
end
o.close

STDERR.puts "#{candidate_ids_f} generated."

### Get pep and cds sequences as well as gff from the list
gfff = cds_file_before.sub(/cds/, "gff3")
output = File.basename(candidate_ids_f, ".ids") + ".gff3"
cmd = "#{$scriptdir}/util/gene_list_to_gff.pl #{candidate_ids_f} #{gfff}.inx > #{output}"
puts cmd
system cmd
gfff = output

bedf = gfff.sub(/gff3$/, "bed")
cmd = "#{$scriptdir}/util/gff3_file_to_bed.pl #{gfff} > #{bedf}"
puts cmd
system cmd

pepf = gfff.sub(/gff3$/, "pep")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{transcriptf}> #{pepf}"
puts cmd
system cmd

cdsf = gfff.sub(/gff3$/, "cds")
cmd = "#{$scriptdir}/util/gff3_file_to_proteins.pl #{gfff} #{transcriptf} CDS > #{cdsf}"
puts cmd
system cmd

