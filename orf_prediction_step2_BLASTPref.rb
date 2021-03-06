#=== conf ===
# $blastdb = "RefSeq_Ath_Osa.pep"
# pepf = "good_orf_candidates.pep"

### Parse command-line options
require 'optparse'
opt = OptionParser.new
opt.on('-i', '--in FASTA', 'predicted protein files in fasta format [required]') {|v| $pepf = v}
opt.on('-d', '--db BLASTDB', 'blastdb [required]') {|v| $blastdb = v}
opt.on('-c', '--ncpu [NCPU]', 'num of CPU to run BLAST [default:8]'){|v| $ncpu = v.to_i}
opt.on('-h', '--help', 'show this message'){
  puts opt; exit
}

opt.parse!(ARGV)
unless $blastdb || $pepf
  raise "\nError: Required option missing.\n"
end

## set default value if options are not specified
$ncpu ||= 8

### start analysis
$scriptdir = File.dirname(__FILE__)

### BLASTP against refseq

evalue = 1.0e-8

cmd = "sh #{$scriptdir}/run_blastp.sh #{$pepf} #{$blastdb} #{$ncpu} #{evalue}"
puts cmd
system cmd
