require 'bio'
include Bio

infasta = ARGV[0]
idlist = ARGV[1]

# ids = {}
fastas = {}

FlatFile.open(infasta).each do |fas|
  fastas[fas.entry_id] = fas
end

File.open(idlist).each do |l|
  id = l.chomp.split[0].strip
  f = fastas[id]
  raise unless f
  puts f
end

