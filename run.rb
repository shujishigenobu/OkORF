require 'yaml'

conff = "run.conf.yml"
y = YAML.load(File.open(conff).read)

p y 

transcriptf = y['transcript_file']

cmd1 = "ruby #{y['libdir']}/orf_prediction_step1_find_goodORFs_for_training.rb -t #{y['transcript_file']}"
runscript1 = "run_script_1.sh"
File.open(runscript1, "w"){|o| o.puts cmd1}
STDERR.puts "#{runscript1} generated"
puts cmd1

cmd2 = "ruby #{y['libdir']}/orf_prediction_step2_BLASTPref.rb -i good_orf_candidates.pep -d #{y['blastdb_train']} -c #{y['ncpu']} "
runscript2 = "run_script_2.sh"
File.open(runscript2, "w"){|o| o.puts cmd2}
STDERR.puts "#{runscript2} generated"
puts cmd2

cdsf = "good_orf_candidates.cds"
pepf = cdsf.sub(/\.cds$/, ".pep")
blastout = "#{pepf}.vs.#{File.basename(y['blastdb_train'])}.blastp.fmt7c.txt"
cmd3 = "ruby #{y['libdir']}/orf_prediction_step3_buildTrainSeq.rb -b #{blastout} -c #{cdsf} -p #{pepf}"
runscript3 = "run_script_3.sh"
File.open(runscript3, "w"){|o| o.puts cmd3}
STDERR.puts "#{runscript3} generated"
puts cmd3

basefreqf = "#{transcriptf}.base_freqs.dat"
cds_for_train = "orfs_for_round2_train.cds"
cmd4 = "ruby #{y['libdir']}/orf_prediction_step4_ORFPredict_round2.rb -t #{transcriptf} -m 50 -b #{basefreqf} -n #{cds_for_train} "
runscript4 = "run_script_4.sh"
File.open(runscript4, "w"){|o| o.puts cmd4}
STDERR.puts "#{runscript4} generated"
puts cmd4

### script 5 : rename outputs
#runscript5 = "run_script_5.sh"
#o = File.open(runscript5, "w")
#pj = y['project']
#newname_base = "ORF_#{pj}"
#
#%w{ good_orf_candidates2.eclipsed_orfs_removed.cds
#good_orf_candidates2.eclipsed_orfs_removed.pep
#good_orf_candidates2.eclipsed_orfs_removed.gff3
#good_orf_candidates2.eclipsed_orfs_removed.bed
#}.each do |f|
#  newname = f.sub(/^good_orf_candidates2.eclipsed_orfs_removed/, newname_base)
#  o.puts "ln -s #{f} #{newname}"
#end
#o.close

### script 6 : rescue -- prep
runscript6 = "run_script_6.sh"
cmd6 = "ruby #{y['libdir']}/orf_prediction_step5_rescueGM_prep.rb  #{transcriptf}  "
File.open(runscript6, "w"){|o| o.puts cmd6}
STDERR.puts "#{runscript6} generated"
puts cmd6


### script 7 : rescue -- run blast

script7s = []
y['rescue_blastdb'].each_with_index do |blastdb, i|

  cmd7 = "ruby #{y['libdir']}/orf_prediction_step2_BLASTPref.rb -i rescued_candidates_300.pep -d #{blastdb} -c #{y['ncpu']} "
  runscript7 = "run_script_7.#{i+1}.sh"
  script7s << runscript7
  File.open(runscript7, "w"){|o| o.puts cmd7}
  STDERR.puts "#{runscript7} generated"
  puts cmd7
end

### script 8 : rescue -- run hmmer (motif search)

pepf = "rescued_candidates_300.pep"
outf = pepf + ".hmmscan.pfam.tbl"
cmd8 = "#{y['libdir']}/pfam_runner.pl --CPU #{y['pfam_ncpu']} -o #{outf} --pfam_db #{y['pfamdb']}  --pep #{pepf} "
runscript8 = "run_script_8.sh"
File.open(runscript8, "w"){|o| o.puts cmd8}
STDERR.puts "#{runscript8} generated"
puts cmd8


### script 9 : rescue -- list from blast and hummer results
blastouts = y['rescue_blastdb'].map{|blastdb| "#{pepf}.vs.#{File.basename(blastdb)}.blastp.fmt7c.txt"}
pfamout = "#{pepf}.hmmscan.pfam.tbl"
cmd9 = "ruby #{y['libdir']}/orf_prediction_stepN_rescueGM_from_BLAST_Pfam.rb -b #{blastouts.join(',')} -p #{pfamout} -g predicted2_orfs.gff3.rmdup -t #{transcriptf}"
runscript9 = "run_script_9.sh"
File.open(runscript9, "w"){|o| o.puts cmd9}
STDERR.puts "#{runscript9} generated"
puts cmd9


### script 10 : merge and filalize
runscript10 = "run_script_10.sh"
o = File.open(runscript10, "w")
cds_files_to_be_merged = ["good_orf_candidates2.eclipsed_orfs_removed.cds", "rescued.cds"]
cmd10 = "ruby #{y['libdir']}/orf_prediction_stepZ_merge_finalize.rb -g predicted2_orfs.gff3.rmdup -t #{transcriptf}  #{cds_files_to_be_merged.join(' ')} "
runscript10 = "run_script_10.sh"
o = File.open(runscript10, "w")
o.puts cmd10
STDERR.puts "#{runscript10} generated"
puts cmd10

pj = y['project']
newname_base = "ORF_#{pj}"
%w{ merged.cds
merged.gff3
merged.bed
merged.pep
}.each do |f|
  newname = f.sub(/^merged/, newname_base)
  o.puts "ln -s #{f} #{newname}"
end
o.close



###
# generate SGE submission script

pj = y['project']

script = <<EOS
qsub -v PATH -N Ok1_#{pj} run_script_1.sh
qsub -v PATH -N Ok2_#{pj} -hold_jid Ok1_#{pj}  -l nc=#{y['ncpu']} run_script_2.sh
qsub -v PATH -N Ok3_#{pj} -hold_jid Ok2_#{pj}  run_script_3.sh
qsub -v PATH -N Ok4_#{pj} -hold_jid Ok3_#{pj}  run_script_4.sh

qsub -v PATH -N Ok6_#{pj} -hold_jid Ok4_#{pj} run_script_6.sh

EOS

rnames = []
script7s.each_with_index do |s, i|
  rname = "Ok7.#{i}_#{pj}"
  script << "qsub -v PATH -N #{rname} -hold_jid Ok6_#{pj} #{s} "
  script << "\n"
  rnames << rname
end

rname = "Ok8_#{pj}"
script << "qsub -v PATH -N #{rname} -hold_jid Ok6_#{pj} run_script_8.sh \n"
rnames << rname

script << "qsub -v PATH -N Ok9_#{pj} -hold_jid #{rnames.join(',')} run_script_9.sh \n"

script << "qsub -v PATH -N Ok10_#{pj} -hold_jid Ok9_#{pj} run_script_10.sh \n"

ofile = "sge_submit_#{pj}.sh"
File.open(ofile, "w"){|o| o.puts script}
STDERR.puts "#{ofile} generated"
