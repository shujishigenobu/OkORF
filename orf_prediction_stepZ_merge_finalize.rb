### Parse command-line options

require 'optparse'

optv = {}

opt = OptionParser.new
opt.on('-g', '--gff GFF3', "original gff3 file (all prediction before filtering"){|v| optv[:gff] = v}
opt.on('-t', '--transcript FASTA', "original transcript_file before filtering"){|v| optv[:transcript] = v}
opt.on('-h', '--help', 'show this message') {
  puts opt; exit
}

opt.parse!(ARGV)

outf = (optv[:outfile] || "rescued.list")
gfff =  optv[:gff]
transcriptf = optv[:transcript]
$scriptdir = File.dirname(__FILE__)

## ARGV : cds fasta files

ids = []
ARGF.each do |l|
  if m = /^>(\S+)\s/.match(l)
    id = m[1]
    ids << id
  end
end

outf =  "merged.list"
File.open(outf, "w"){|o| o.puts ids}

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
