#!/usr/bin/env perl

################################################
#                                              
# SCRIPT: otp-project-softlinker.pl
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
# HISTORY
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
# VERSION: 0.4
# Full: processing of WGS, WES, RNAseq (no support for older OTP alignments)
# Also checks for bams in any WGS and WES subfolder and links to them [slow! perhaps make this an option...]
# Links to all DNAseq analysis subtypes which are defined in %wgs_analysis_types (key = analysis type, value = preffix of softlinked folder)
# Links to QC for everything else
# process input options
#
# VERSION: 0.5
# Best left forgotten.
# Tried to mimic the Roddy ACEseq folder naming (ACEseq_tumor), but this causes problems with multiple control types
#
# VERSION: 0.6
# Support for individual PIDs
#
# VERSION: 0.7
# Makes additional default folder for otp QC output
#
# VERSION: 1.0.0
# First stable release (based on 0.7)
################################################

use strict;
use warnings;
use DateTime;
use Getopt::Long qw(GetOptions);

##### PARSE INPUT #####

my $usage = "\nThis script creates a directory structure for projects from those in OTP\n\n\t $0 -input_dir /icgc/dkfzlsdf/project/hipo/hipo_XXX -output_dir /icgc/dkfzlsdf/analysis/hipo/hipo_XXX [-pids \"HXXX-ABCD,HXXX-EFGH\"] [help]\n\n";

my $project_dir;
my $out_dir;
my $pid_string;
my @pid_string_split;
my $help;

GetOptions('input_dir=s'  => \$project_dir,
           'output_dir=s' => \$out_dir,
           'pids=s'       => \$pid_string,
           'help'         => \$help);    

if ($help){
  print "$usage";
  exit;
}

if (!(defined $project_dir) || !(defined $out_dir)){
  print "ERROR: You need to define an input_dir and an output_dir!\n$usage";
  exit;
}

if (defined $pid_string){
  print "\#PID list defined: \"$pid_string\"\n";
  @pid_string_split = split ",", $pid_string;
  foreach my $pid (@pid_string_split){
    print "\#PID:$pid\n";
  }
  
}
else{
  print "\#WANRING: no pids defined - will run on all pids\n";
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
  print "mkdir $out_dir/$array_type_array/otp_output_QC\n";
}

foreach my $seq_type (@seq_types){
 chomp ($seq_type);
  next if ($seq_type eq "[none]");
  print "mkdir $out_dir/$seq_type\n";
  print "mkdir $out_dir/$seq_type/processing_scripts\n";
  print "mkdir $out_dir/$seq_type/results_per_pid\n";
  print "mkdir $out_dir/$seq_type/cohort_analysis\n";
  print "mkdir $out_dir/$seq_type/otp_output_QC\n";
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
  @pids = @pid_string_split if defined ($pid_string);
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

      my %wgs_analysis_types;
      $wgs_analysis_types{"snv_results"}="mpileup_";
      $wgs_analysis_types{"sv_results"}="SOPHIA_";
      $wgs_analysis_types{"indel_results"}="platypus_indel_";
      $wgs_analysis_types{"cnv_results"}="ACEseq_";

      foreach my $wgs_analysis_type (keys %wgs_analysis_types){
        print "\n\# Looking for $wgs_analysis_type for $pid WGS...\n";
        if (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/$wgs_analysis_type"){
          print "\n\# SOFTLINKG SNV FILES FOR $pid\n";
          my @comparisons = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$wgs_analysis_type/paired/`;
          foreach my $comparison (@comparisons){
            chomp ($comparison);
            my $res_folder = `ls -tr $project_dir/sequencing/$seq_type/view-by-pid/$pid/$wgs_analysis_type/paired/$comparison | tail -n 1`;
            chomp($res_folder);
            my @files = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$wgs_analysis_type/paired/$comparison/$res_folder/`;
            print "mkdir $out_dir/$seq_type/results_per_pid/$pid/$wgs_analysis_types{$wgs_analysis_type}"."$comparison"."\n";
            foreach my $file (@files){
              chomp ($file);
              print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$wgs_analysis_type/paired/$comparison/$res_folder/$file $out_dir/$seq_type/results_per_pid/$pid/$wgs_analysis_types{$wgs_analysis_type}$comparison"."\n";
            }
          }
        }
      }
    } 

    # RNASEQ

    elsif ($seq_type eq "rna_sequencing"){
      # /icgc/dkfzlsdf/project/hipo2/hipo_K20K/sequencing/rna_sequencing/view-by-pid/K20K-7FN3KK/patient-derived-culture1/paired/merged-alignment/
      my @tissues = `ls $project_dir/sequencing/$seq_type/view-by-pid/$pid`;
      foreach my $tissue (@tissues){
        # ALIGNMENT
        chomp $tissue;
        print "$project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/\n";
        if (-e "$project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/"){
          print "mkdir $out_dir/$seq_type/results_per_pid/$pid/alignment\n";
          my @files =`ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment | grep $pid`;
          foreach my $file (@files){
            chomp $file;
            print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/$file $out_dir/$seq_type/results_per_pid/$pid/alignment/$file\n";
          }

          #OTHER RNASEQ ANALYSIS
          my @directories =`ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment | grep -v $pid`;
          foreach my $directory (@directories){
            chomp $directory;
            print "\n\#MAKING $directory SUBDIR...\n";
            print "mkdir $out_dir/$seq_type/results_per_pid/$pid/$directory\n";
            my @files =`ls $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/$directory`;
            foreach my $file (@files){
              chomp $file;
              if ($directory eq "qualitycontrol") {
                print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/$directory/$file $out_dir/$seq_type/results_per_pid/$pid/$directory/$tissue"."_"."$pid"."_"."$file\n";
              }
              else {
                print "ln -s $project_dir/sequencing/$seq_type/view-by-pid/$pid/$tissue/paired/merged-alignment/$directory/$file $out_dir/$seq_type/results_per_pid/$pid/$directory/$file\n";
              }
            }
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
