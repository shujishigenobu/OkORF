#!/usr/bin/env perl

use FindBin;
use lib ("$FindBin::Bin/PerlLib");

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);
use Gene_obj;
use Nuc_translator;
use Fasta_reader;
use Longest_orf;
use List::Util qw (min max);

use Data::Dumper;
use YAML;


my $transcripts_file = $ARGV[0];
my $prefix = ($ARGV[1] || "test");

my $UTIL_DIR = "$FindBin::Bin/util";
my $min_prot_length = 100;
$min_prot_length = $ARGV[2] if $ARGV[2];

my $genetic_code;
my $TOP_STRAND_ONLY = 0;

unless ($transcripts_file) {
    die "Need transcript file";
}


if ($genetic_code) {
    &Nuc_translator::use_specified_genetic_code($genetic_code);
}


# my $prefix = "longest_orfs";
my $cds_file = "$prefix.cds";
my $gff3_file = "$prefix.gff3";
my $pep_file = "$prefix.pep";


open (PEP, ">$pep_file") or die $!;
open (CDS, ">$cds_file") or die $!; 
open (GFF, ">$gff3_file") or die $!;

my $counter = 0;
	
my $fasta_reader = new Fasta_reader($transcripts_file);
while (my $seq_obj = $fasta_reader->next()) {
		
    my $acc = $seq_obj->get_accession();
    my $sequence = $seq_obj->get_sequence();
    
    my $longest_orf_finder = new Longest_orf();
    $longest_orf_finder->allow_5prime_partials();
    $longest_orf_finder->allow_3prime_partials();
		
    if ($TOP_STRAND_ONLY) {
	$longest_orf_finder->forward_strand_only();
    }
		
    my @orf_structs = $longest_orf_finder->capture_all_ORFs($sequence);
    
    @orf_structs = reverse sort {$a->{length}<=>$b->{length}} @orf_structs;
    
    while (@orf_structs) {
	my $orf = shift @orf_structs;
	
	my $start = $orf->{start};
	my $stop = $orf->{stop};
            
	if ($stop <= 0) { $stop += 3; } # edge issue
            
	my $length = int($orf->{length}/3);
	my $orient = $orf->{orient};
	my $protein = $orf->{protein};
            
	if ($length < $min_prot_length) { next; }
            
	my $coords_href = { $start => $stop };
            
	my $gene_obj = new Gene_obj();
            
	$counter++;
	$gene_obj->populate_gene_object($coords_href, $coords_href);
	$gene_obj->{asmbl_id} = $acc;
            
	my $model_id = "m.$counter";
	my $gene_id = "g.$counter";
            
            
	$gene_obj->{TU_feat_name} = $gene_id;
	$gene_obj->{Model_feat_name} = $model_id;

            
	my $cds = $gene_obj->create_CDS_sequence(\$sequence);
            
	my $got_start = 0;
	my $got_stop = 0;
	if ($protein =~ /^M/) {
	    $got_start = 1;
	} 
	if ($protein =~ /\*$/) {
	    $got_stop = 1;
	}
            
	my $prot_type = "";
	if ($got_start && $got_stop) {
	    $prot_type = "complete";
	} elsif ($got_start) {
	    $prot_type = "3prime_partial";
	} elsif ($got_stop) {
	    $prot_type = "5prime_partial";
	} else {
	    $prot_type = "internal";
	}
	
	$gene_obj->{com_name} = "ORF $gene_id $model_id type:$prot_type len:$length ($orient)";            
            
	print PEP ">$model_id $gene_id type:$prot_type len:$length $acc:$start-$stop($orient)\n$protein\n";
	
	print CDS ">$model_id $gene_id type:$prot_type len:$length\n$cds\n";
            
	print GFF $gene_obj->to_GFF3_format() . "\n";

    }
}

close PEP;
close CDS;
close GFF;
    


