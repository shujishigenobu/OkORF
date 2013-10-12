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

### rename outputs
pj = y['project']
newname_base = "ORF_#{pj}"

%w{ good_orf_candidates2.eclipsed_orfs_removed.cds
good_orf_candidates2.eclipsed_orfs_removed.pep
good_orf_candidates2.eclipsed_orfs_removed.gff3
good_orf_candidates2.eclipsed_orfs_removed.bed
}.each do |f|
  newname = f.sub(/^good_orf_candidates2.eclipsed_orfs_removed/, newname_base)
  File.symlink(f, newname)
end


###
# generate SGE submission script

pj = y['project']

script = <<EOS
qsub -v PATH -N Ok1_#{pj} run_script_1.sh
qsub -v PATH -N Ok2_#{pj} -hold_jid Ok1_#{pj}  -l nc=#{y['ncpu']} run_script_2.sh
qsub -v PATH -N Ok3_#{pj} -hold_jid Ok2_#{pj}  run_script_3.sh
qsub -v PATH -N Ok4_#{pj} -hold_jid Ok3_#{pj}  run_script_4.sh
EOS

ofile = "sge_submit_#{pj}.sh"
File.open(ofile, "w"){|o| o.puts script}
STDERR.puts "#{ofile} generated"
