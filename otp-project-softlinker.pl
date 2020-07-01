#!/usr/bin/env perl

################################################
#                                              
# SCRIPT: project_softlinker.pl
#
################################################
#
# AUTHOR: Naveed Ishaque (naveed.ishaque@dkfz.de)
# DATE: JUL 2016
#
# REQUIRES: path to a project folder in the dkfzlsdf
# OUTPUT: creates shell script for softlinking folder structure to the project folder data
#
# FOLDER SUPPORT: array, sequencing
# DATA SUPPORT: alignment, QC, SNVs, softlink "core" folder of arrays
#
################################################
#
# NISTORY
#
# VERSION: 0.1b
# 11 JULY 2016
# No checks, just creates folders
# Who needs comments?
#
# VERSION: 0.2b
# Full: processing of WGS and WES
# Links to QC of RNAseq, chipseq, WGBS, medip_sequencing, panel_sequencing, snc_rna_sequencing
#
# VERSION: 0.3b
# Full: processing of WGS, WES (no support for older OTP alignments)
# Also checks for bams in any WGS and WES subfolder and links to them [slow! perhaps make this an option...]
# Links to QC for everything else
# process input options
#
################################################

use strict;
use warnings;
use DateTime;
use Getopt::Long qw(GetOptions);

##### PARSE INPUT #####

my $usage = "\nThis script creates a directory structure for projects from those in OTP\n\n\t $0 -input_dir /icgc/dkfzlsdf/project/hipo/hipo_XXX -out_dir /icgc/dkfzlsdf/analysis/hipo/hipo_XXX [-help]\n\n";

my $project_dir;
my $out_dir;
my $help;

GetOptions('input_dir=s'  => \$project_dir,
           'output_dir=s' => \$out_dir,
           'help'         => \$help);    

if ($help){
  print "$usage";
  exit;
}

if (!(defined $project_dir) || !(defined $out_dir)){
  print "ERROR: You need to define an input_dir and an output_dir!\n$usage";
  exit;
}

##### FOLDER INFORMATION #####

print "\n\# PROCESSING: \"$project_dir\"\n\# OUTPUT DIRECTORY: \"$out_dir\"\n";

my $dt   = DateTime->now;  
print "\# DATE TIME: $dt\n\n";

my @array_types = "[none]";
my @seq_types = "[none]";

@array_types = `ls $project_dir/array` if (-e "$project_dir/array");
@seq_types = `ls $project_dir/sequencing`  if (-e "$project_dir/sequencing");

foreach my $array_type (@array_types){
  chomp ($array_type);
  print "\# FOUND ARRAY TYPE: $array_type\n";
}

foreach my $seq_type (@seq_types){
  chomp ($seq_type);
  print "\# FOUND SEQUENCING TYPE: $seq_type\n";
}

##### START CREATING DIRECTORY STRUCTURE #####

print "\n# MAKING SEQ/ARRAY DIRECTORYS\n\n";

print "mkdir $out_dir\n";

foreach my $array_type (@array_types){
  chomp ($array_type);
  next if ($array_type eq "[none]");
  my $array_type_array = $array_type. "_array";
  print "mkdir $out_dir/$array_type_array\n";
  print "mkdir $out_dir/$array_type_array/processing_scripts\n";
  print "mkdir $out_dir/$array_type_array/results_per_pid\n";
  print "mkdir $out_dir/$array_type_array/cohort_analysis\n";
}

foreach my $seq_type (@seq_types){
 chomp ($seq_type);
  next if ($seq_type eq "[none]");
  print "mkdir $out_dir/$seq_type\n";
  print "mkdir $out_dir/$seq_type/processing_scripts\n";
  print "mkdir $out_dir/$seq_type/results_per_pid\n";
  print "mkdir $out_dir/$seq_type/cohort_analysis\n";
}

##### CREATE ARRAY SUBDIRS/FILES #####

print "\n# MAKING ARRAY SUBDIRECTORYS\n\n";

foreach my $array_type (@array_types){
  chomp ($array_type);
  next if ($array_type eq "[none]");
  my $array_type_array = $array_type. "_array";
  print "ln -s  $project_dir/array/$array_type/core $out_dir/$array_type_array/core\n";
}

##### CREATE SEQUENCING SUBDIRS/FILES #####

print "\n# MAKING SEQUENCING SUBDIRECTORYS\n\n";

foreach my $seq_type (@seq_types){
  chomp ($seq_type);
  next if ($seq_type eq "[none]");
  my @pids = `ls $project_dir/sequencing/$seq_type/view-by-pid`;
  foreach my $pid (@pids){
    chomp $pid;
    print "\n\#PROCESSING $seq_type $pid\n\n";
    print "mkdir $out_dir/$seq_type/results_per_pid/$pid\n";
   
    if ($seq_type eq "whole_genome_sequencing" || $seq_type eq "exon_sequencing"){

      print "\n\# SOFTLINKG ALIGNMENT FILES FOR $pid\n";

      # LINK ALIGNMENT FILES
  
      print "mkdir $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
      if (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/*/paired/merged-alignment/*bam"){
        my @alignment_files = ` ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/*/paired/merged-alignment/*bam`;
        foreach my $alignment_file (@alignment_files){
          chomp ($alignment_file);
          print "ln -s $alignment_file $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
        }
        my @index_files = ` ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/*/paired/merged-alignment/*bai`;
        foreach my $index_file (@index_files){
          chomp ($index_file);
          print "ln -s $index_file $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
        }
        my @md5sum_files = ` ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/*/paired/merged-alignment/*md5*`;
        foreach my $md5sum_file (@md5sum_files){
          chomp ($md5sum_file);
          print "ln -s $md5sum_file $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
        }
      }

      unless (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/*/paired/merged-alignment/*bam"){
      
        my @alignment_files = `find $project_dir/sequencing/$seq_type/view-by-pid/$pid/*/*/ -type f -name *bam`;
        foreach my $alignment_file (@alignment_files){
          chomp ($alignment_file);
          print "ln -s $alignment_file $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
        }
        my @index_files = ` find $project_dir/sequencing/$seq_type/view-by-pid/$pid/*/*/ -type f -name *bai`;
        foreach my $index_file (@index_files){
          chomp ($index_file);
          print "ln -s $index_file $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
        }

      }  

      # LINK QC FILES

      print "\n\# SOFTLINKG QC FILES FOR $pid\n";

      print "mkdir $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol\n";

      my @tissues = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/`;
      foreach my $tissue (@tissues){
        chomp ($tissue);
        next unless (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/qualitycontrol");
        print "mkdir $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol/$tissue\n";
        my @qc_files = ` ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/qualitycontrol`;
        foreach my $qc_file (@qc_files){
          chomp ($qc_file);
          print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/qualitycontrol/$qc_file $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol/$tissue\n";
        }
      }

      # LINK SNV FILES
 
      if (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/snv_results"){
        print "\n\# SOFTLINKG SNV FILES FOR $pid\n";
        my @snv_comparisons = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/snv_results/*/`;
        foreach my $snv_comparison (@snv_comparisons){
          chomp ($snv_comparison);
          my @snv_files = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/snv_results/*/$snv_comparison`;
          print "mkdir $out_dir/$seq_type/results_per_pid/$pid/mpileup_"."$snv_comparison"."\n";
          foreach my $snv_file (@snv_files){
            chomp ($snv_file);
            print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/snv_results/paired/$snv_comparison/$snv_file $out_dir/$seq_type/results_per_pid/$pid/mpileup_"."$snv_comparison"."\n";
          }
          if (scalar @snv_comparisons == 1){
          print "ln -s mpileup_"."$snv_comparison $out_dir/$seq_type/results_per_pid/$pid/mpileup\n";
          }        
        }
      }
    }

    elsif ($seq_type eq "SOMETHING PARSEABLE IN THE FUTURE"){
      # DO MORE PARSING
    }

    else {
      
      print "\n\# SOFTLINKING $seq_type QC FOR $pid\n";
 
      print "mkdir $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol\n";
      my @tissues = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/`;
      foreach my $tissue (@tissues){
        chomp ($tissue);
        print "mkdir $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol/$tissue\n";
        my @tissue_lanes = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/*/`;
        foreach my $tissue_lane (@tissue_lanes){
          chomp ($tissue_lane);
          print "mkdir $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol/$tissue/$tissue_lane\n";
          print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/*/$tissue_lane/fastx_qc/ $out_dir/$seq_type/results_per_pid/$pid/qualitycontrol/$tissue/$tissue_lane\n"
        }
      }
    }
  }
}

##### XXX #####



##### XXX #####



##### XXX #####

print "\n\# DONE!\n\n";

exit;
