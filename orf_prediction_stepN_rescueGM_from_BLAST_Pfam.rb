### Parse command-line options

require 'optparse'

optv = {}

opt = OptionParser.new
opt.on('-b', '--blast BLAST1,BLAST2,...', 'blast results in format7. multiple results can be given.') {|v| optv[:blast_results] = v}
opt.on('-p', '--pfam PFAM', 'pfam searhc results') {|v| optv[:pfam_result] = v}
opt.on('-o', '--outfile', "output file"){|v| optv[:outfile]}
opt.on('-g', '--gff GFF3', "original gff3 file (all prediction before filtering"){|v| optv[:gff] = v}
opt.on('-t', '--transcript FASTA', "transcript_file"){|v| optv[:transcript] = v}
opt.on('-h', '--help', 'show this message') {
  puts opt; exit
}

opt.parse!(ARGV)

outf = (optv[:outfile] || "rescued.list")
gfff =  optv[:gff]
transcriptf = optv[:transcript]
$scriptdir = File.dirname(__FILE__)

p optv

models_with_hit = []
blast_results = optv[:blast_results].split(/,/)
blast_results.each do |b|
  File.open(b).each do |l|
    next if /^\#/.match(l)
    models_with_hit << l.chomp.split(/\t/)[0]
  end
end


File.open(optv[:pfam_result]).each do |l|
  a = l.chomp.split(/\s+/)
  models_with_hit << a[3]
end

p models_with_hit.size
models_with_hit.sort!
models_with_hit.uniq!
p models_with_hit.size

File.open(outf, "w"){|o|
  o.puts models_with_hit
}


### Get pep and cds sequences as well as gff from the list

p gfff
gfff  #original gff before filtreing
output = File.basename(outf, ".list") + ".gff3"
cmd = "#{$scriptdir}/util/gene_list_to_gff.pl #{outf} #{gfff}.inx > #{output}"
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
