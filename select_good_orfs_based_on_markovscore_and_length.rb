require 'bio'
include Bio


cdsf = (ARGV[0] || "longest_orfs.cds")
scoref = (ARGV[1] || "#{cdsf}.scores")
len_retain_long_orfs = (ARGV[2] || 900).to_i # bp

orf_length = {}

FlatFile.open(FastaFormat, cdsf).each do |fas|
  orf_length[fas.entry_id] = fas.seq.size
end

STDERR.puts len_retain_long_orfs

File.open(scoref).each do |l|
  criteria = {:markov_score => false, :long_orf => false}
  a = l.chomp.split(/\t/)
  id = a.shift
  score = a.map{|x| x.to_f}
  criteria[:markov_score] = true if score[0] > 0 && score[0] > score[1, 5].max 
  criteria[:long_orf] = true if orf_length[id] >= len_retain_long_orfs
  if (criteria[:markov_score] || criteria[:long_orf])
    puts [id, orf_length[id], a, criteria.inspect].flatten.join("\t")
  end
end

