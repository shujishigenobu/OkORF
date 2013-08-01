blast7 = ARGV[0]

prev_line = ""
File.open(blast7).each do |l|
  next if /^\#/.match(l)
  a = l.chomp.split(/\t/, -1)
  query = a[0]
  query_prev = prev_line.split(/\t/, -1)[0]

  unless query == query_prev
#    puts l 

    qid = a[0]
    sid = a[1]
    perc_identity = a[2].to_f
    align_len = a[3].to_i
    qlen = a[12].to_i
    slen = a[13].to_i
    evalue = a[10].to_f
    
#p    [qid, sid, perc_identity, align_len, qlen, slen]

    len_diff_perc = (qlen/slen.to_f - 1.0).abs * 100
    len_avg = (qlen + slen) / 2.0
    
    aln_ratio = (align_len / len_avg) 

#    p [qid, sid, perc_identity, align_len, qlen, slen, len_diff, aln_ratio]

    if (perc_identity > 30.0  &&
        aln_ratio > 0.5 &&
        len_diff_perc < 20 &&
        qlen > 300 &&
        evalue < 1.0e-8
        )
      
      puts [qid, sid, perc_identity, align_len, qlen, slen, len_diff_perc, aln_ratio, "*"].join("\t")
    end

  end

  prev_line = l
end
