require 'bio'
include Bio

gff = ARGV[0]
idlist = ARGV[1]

# ids = {}
gffs = {}

File.open(gff).each("\n\n") do |rec|
  gid = /ID\=(g.\d+);/.match(rec)[1]
  mid = /ID\=(m.\d+);/.match(rec)[1]
  gffs[mid] = rec
end

File.open(idlist).each do |l|
  id = l.chomp.split[0].strip
  rec = gffs[id]
  raise unless rec
  puts rec
end

