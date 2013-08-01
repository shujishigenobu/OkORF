require 'bio'

include Bio

f = ARGV[0]

seqs={}
count = 0
FlatFile.open(FastaFormat, f).each do |fas|
  count += 1
  seq = fas.seq
  unless seqs.has_key?(seq)
    seqs[seq] = []
  end
  seqs[seq] << fas
end

seqs.keys.each do |k|
  representative = seqs[k][0]
  puts representative
end

STDERR.puts "input:  #{count}"
STDERR.puts "output: #{seqs.keys.size}"


