#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long "GetOptions";

#Hot-fix:
#my $HOME=$ENV{'HOME'};
#my $HOME='/home/christof/';
#my $SMTAMS=$ENV{'SMTAMS'};


my @args=@ARGV;
for(my $i=0; $i<@args; $i++) {
    if($args[$i]=~/[\= ]\-/ || $args[$i]=~/ /) {
	my($feature,$value)=$args[$i]=~/^([^ \=]+?)[\= ](.+)$/;
	$args[$i]="$feature\=\"$value\"";
    }
}
my $arg_string=join(' ',@args);
print STDERR "call: $0 $arg_string\n\n";

#BEGIN {
#    if(!defined($ENV{'OISTERHOME'})
#       || $ENV{'OISTERHOME'} eq '') {
#        print STDERR "environment variable OISTERHOME must be set:\n";
#        print STDERR "export OISTERHOME=/path/to/oister/distribution\n";
#        exit(-1);
#    }
#}

#BEGIN {
#    my $release_info=`cat /etc/*-release`;
#    $release_info=~s/\n/ /g;
#    my $os_release;
#    if($release_info=~/CentOS release 5\./) {
#        $os_release='CentOS_5';
#    } elsif($release_info=~/CentOS release 6\./) {
#        $os_release='CentOS_6';
#    }
#    if($os_release eq 'CentOS_6') {
#        unshift @INC, $ENV{"OISTERHOME"}."/lib/perl_modules/lib64/perl5"
#    } else {
#        unshift @INC, $ENV{"OISTERHOME"}."/resources/bin/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi"
#    }
#}

use PerlIO::gzip;

#$ENV{'LC_COLLATE'}='C';
#my $OISTERHOME=$ENV{'OISTERHOME'};

#my $moses_trunk="$HOME/resources/software/moses/mosesdecoder/mosesdecoder/trunk";

my $clean_up=1;

my $num_batches;
my $no_parallel;
my $corpus_stem;
my $replace_corpus_stem;
my $background_corpus_stem;
my $replace_background_corpus_stem;
my $dict_stem;
my $replace_dict_stem;
my $add_dict;
my $add_background;
my $f_suffix;
my $e_suffix;
my $experiment_dir;
my $use_mgiza=0;
my $build_phrase_table=0;
my $build_distortion_model=0;
my $alignment_strategies='m1-m5:grow-diag-final-and';
my $lex_probs;
my $dm_interpolation=0.75;
#my $block_count=0;
my $sigtest_filter='a+e';
my $compressed_sort;
my $use_moses_orientation=0;
my $use_dlr=0;
my $use_hdm=0;
my $dm_languages='fe';
my $external_path;
my $ibm1_exists=0;
my $max_phrase_length=7;
my $bilm_string;

#resources/software/moses/training/train-factored-phrase-model-less-disk-usage.perl";

#$HOME/scripts/moses-train-wrapper.pl";
#my $delete_function_links_script="$OISTERHOME/build/bitext_models/scripts/delete-function-word-alignment.pl";

my $berkeley_em_threads=12;
my $additional_moses_parameters;
my $_HELP;
my $delete_function_links=0;
my $skip_align=0;
my $sparse_feature_options='';
my $phrase_table_smoothing_string;
my $lexical_weighting_string;
my $num_ibm1_iterations=5;
my $align_background_corpus_stem;
my $add_background_num;
my $add_dict_num;
my $duplicate_background_num;
my $duplicate_dict_num;
my $misc_corpus_string='';
my $misc_background_corpus_string='';
my $align_corpus_stem;
my $align_dict_stem;
my $pos_corpus_stem;
my $pos_background_corpus_stem;
my $pos_dict_stem;
my $pos_trans_string;
my $use_tmpfs=0;
my $tmpfs_loc='/dev/shm/';
my $ignore_word_alignment_errorlog=0;
my $dependencies_path;

$_HELP = 1
    unless &GetOptions(
	"f=s" => \$f_suffix,
	"e=s" => \$e_suffix,
	"corpus=s" => \$corpus_stem,
	"pos-corpus=s" => \$pos_corpus_stem,
	"align-corpus=s" => \$align_corpus_stem,
	"background-corpus=s" => \$background_corpus_stem,
	"pos-background-corpus=s" => \$pos_background_corpus_stem,
	"align-background-corpus=s" => \$align_background_corpus_stem,
        "mgiza" => \$use_mgiza,
	"dict=s" => \$dict_stem,
	"pos-dict=s" => \$pos_dict_stem,
	"align-dict=s" => \$align_dict_stem,
        "add-background=i" => \$add_background_num,
        "add-dict=i" => \$add_dict_num,
        "duplicate-background=i" => \$duplicate_background_num,
        "duplicate-dict=i" => \$duplicate_dict_num,
	"misc-corpus=s" => \$misc_corpus_string,
	"misc-background-corpus=s" => \$misc_background_corpus_string,
#
#
#	"corpus-stem=s" => \$corpus_stem,
#	"replace-corpus-stem=s" => \$replace_corpus_stem,
#	"background-corpus-stem=s" => \$background_corpus_stem,
#	"replace-background-corpus-stem=s" => \$replace_background_corpus_stem,
#	"dict-stem=s" => \$dict_stem,
#	"replace-dict-stem=s" => \$replace_dict_stem,
#	"add-dict=i" => \$add_dict,
#	"add-background" => \$add_background,
	"no-batches=i" => \$num_batches,
	"no-parallel=i" => \$no_parallel,
        "compressed-sort" => \$compressed_sort,
	"moses-params=s" => \$additional_moses_parameters,
	"experiment-dir=s" => \$experiment_dir,
	"build-phrase-table" => \$build_phrase_table,
	"build-distortion-model" => \$build_distortion_model,
	"dm-lang=s" => \$dm_languages,
	"moses-orientation" => \$use_moses_orientation,
	"use-dlr" => \$use_dlr,
	"use-hdm|use-hrm" => \$use_hdm,
	"delete-function-links" => \$delete_function_links,
	"distortion-model-interpolation=s" => \$dm_interpolation,
	"alignment-strategies=s" => \$alignment_strategies,
	"lex-probs=s" => \$lex_probs,
	"sigtest-filter=s" => \$sigtest_filter,
        "skip-align" => \$skip_align,
        "sparse-features=s" => \$sparse_feature_options,
        "pt-smoothing|phrase-table-smoothing=s" => \$phrase_table_smoothing_string,
        "lex-weights=s" => \$lexical_weighting_string,
        "num-ibm1-iterations=i" => \$num_ibm1_iterations,
        "pos-trans=s" =>\$pos_trans_string,
        "bilm=s" => \$bilm_string,
        "berkeley-em-threads|em-threads=i" => \$berkeley_em_threads,
        "tmpfs|tempfs" => \$use_tmpfs,
        "tmpfs-loc|tempfs-loc=s" => \$tmpfs_loc,
	"ignore-alignment-errorlog|ignore-alignment-error-log" => \$ignore_word_alignment_errorlog,
    "dependencies=s" => \$dependencies_path,
	"help|h" => \$_HELP,
    );

#print STDERR "SPARSE:$sparse_feature_options\n";

#if($alignment_strategies!~/((grow-diag-final(\-and)?)|intersect|union|hmm)$/) {
if($alignment_strategies!~/(m1-m5|berkeley|hmm)/) {
    print STDERR "parameter alignment-strategies=$alignment_strategies unknown\n";
    exit(-1);
}

if(!defined($f_suffix)) {
    $_HELP=1;
}

#if(exists($ENV{'OISTEREXTPATH'}) && defined($ENV{'OISTEREXTPATH'})) {
#    $external_path=$ENV{'OISTEREXTPATH'};
#}

#if(!defined($external_path)) {
#    print STDERR "  --external-path=str must be set\n";
#    $_HELP=1;
#}

#if($block_count!~/^[0-9]+$/ && $block_count!~/^[0-9]+(\,[0-9]+)*$/) {
#    print STDERR "--block-count=[0-9]+(\,[0-9]+)\n";
#    exit(-1);
#}
if(!defined($dependencies_path)) {
    print STDERR "  --dependencies=str must be set to the dependencies folder\n";
    $_HELP=1;
}


if($_HELP) {
    print "\nOptions:
  --f : foreign-side suffix (e.g., 'ar', 'fr', ...)
  --e : target-side suffix (e.g., 'en', 'de', ...)
  --corpus-stem : stem of the bitext
  --bitext-pos-f=str :
  --background-corpus-stem : background corpus added to each batch (optional)
  --dict-stem : stem of the dict bitext (optional)
  --add-dict: add the dictionary to aligned output (default=1)
  --add-background: add background corpus to aligned output (default=0)
  --compressed-sort : use compressed (gzipped) version of sort (default=0)
  --mgiza : use mgiza
  --alignment-strategies : list of aligners/refiners
  --lex-probs : list of aligners/refiners for lex.f2n/n2f
  --no-batches: number of splits (default=1)
  --no-parallel : maximum number of parallel runs (default=1)
  --moses-params : additional optional moses training parameters
  --moses-orientation : use moses orientation counts
  --use-dlr (use discontinous left+right)
  --use-hdm (use hierarchical distortion modeling)
  --dm-lang=string ('fe,f,e' or 'fe,e' or 'fe'=default)
  --delete-function-links : delete non-1-1 function word alignments
  --skip-align : skip the word alignment steps
  --sparse-features : string includes --word-pairs --freq-bins --insert-trg --phrase-length
  --lex-weights=str: comma-separated
                 ( values: noisy-or-ibm1 noisy-or-rf ibm1-ibm1 ibm1-rf)
  --num-ibm1-iterations=int : number of iterations of IBM1 (default=5)
  --pt-smoothing=str : comma-separated string (values: kn gt elf)
  --pos-trans=str : comma-separated values={pos-pos,lex-pos,length-pos}
  --bilm=str : comma-separated values={w-w,p-p,p-w,p-w,w-x,p-x}
  --berkeley-em-threads : number of cores used by Berkeley aligner
  --tmpfs : use tmpfs
  --tmpfs-loc=str : tmpfs path (default=/dev/shm/)
  --ignore-alignment-errorlog : all GIZA++/BerkelyAligner errors are written to /dev/null
  --dependencies=string (path to dependencies folder)
  --help : print this message.\n\n";
    exit(-1);
}

print STDERR "Unprocessed by Getopt::Long\n" if $ARGV[0];
foreach (@ARGV) {
  print STDERR "$_\n";
}

my $berkeley_train_script="$dependencies_path/build/bitext_models/scripts/berkeley-aligner.pl";
my $berkeley_aligner_wrapper="$dependencies_path/build/bitext_models/scripts/berkeley-aligner-wrapper.pl";
my $moses_train_wrapper="$dependencies_path/build/bitext_models/moses-train-wrapper.pl";
my $moses_train_script="$dependencies_path/moses/scripts/training/train-model.perl";

my @config_pt_lines;
$config_pt_lines[0]='feature:phrase_table[0].t(f|e)=0.01(-10)         init=0.1[0.1,0.3]  opt=0.1[0.1,0.3]';
$config_pt_lines[1]='feature:phrase_table[1].l(f|e)=0.01(-10)         init=0.1[0.1,0.3]  opt=0.1[0.1,0.3]';
$config_pt_lines[2]='feature:phrase_table[2].t(e|f)=0.01(-10)         init=0.1[0.1,0.3]  opt=0.1[0.1,0.3]';
$config_pt_lines[3]='feature:phrase_table[3].l(e|f)=0.01(-10)         init=0.1[0.1,0.3]  opt=0.1[0.1,0.3]';
$config_pt_lines[4]='feature:phrase_table[4].phrase_penalty(e|f)=0.11(-10)         init=-0.5[0.1,0.3]  opt=0.1[0.1,0.3]';


$num_batches||=1;
$no_parallel||=1;
$add_dict||=1;
$add_background||=0;
$additional_moses_parameters||='';
$experiment_dir||='.';
$compressed_sort=0 if(!defined($compressed_sort));
my $mgiza_cpu=$no_parallel;


if($compressed_sort) {
# this needs to be sorted out later on
#    $moses_train_script="$HOME/resources/software/moses/current/moses/scripts/training/train-factored-phrase-model-less-disk-usage-compress.perl";
}

my $current_dir=`pwd`;
chomp($current_dir);
print STDERR "current_dir=$current_dir\n";

my $experiment_dir_full_path;
if($experiment_dir=~/^\//) {
    $experiment_dir_full_path=$experiment_dir;
} else {
    $experiment_dir_full_path="$current_dir/$experiment_dir";
    $experiment_dir_full_path=~s/\/(\.\/)+/\//g;
    while($experiment_dir_full_path=~s/\/[^\/]+\/\.\.\//\//) {
    }
}
$experiment_dir_full_path=~s/\/\.$//;

my $tmp_align_dir="tmp_align.$$";
if($use_tmpfs) {
    system("mkdir $tmpfs_loc/$tmp_align_dir");
}

print STDERR "experiment_dir_full_path=$experiment_dir_full_path\n";

#m1-m5:grow-diag-final-and:f2e:e2f
#hmm:grow-diag-final-and:f2e:e2f
#berkeley:nil

my $berkeley_m1_iter=5;
my $berkeley_hmm_iter=5;

my @align_strategies=split(/\,/,$alignment_strategies);
my @lex_prob_strategies=split(/\,/,$lex_probs);
my %aligner_runs_hash;
my %refiners;
my %bitext_refiners;
for(my $i=0; $i<@align_strategies; $i++) {
    if($align_strategies[$i]=~/^m1-m5:(.+)$/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'m1-m5'}{$tmp[$i]}=1;
	    $bitext_refiners{'m1-m5'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'m1-m5'}=1;
    } elsif($align_strategies[$i]=~/^hmm:(.+)/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'hmm'}{$tmp[$i]}=1;
	    $bitext_refiners{'hmm'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'hmm'}=1;
    } elsif($align_strategies[$i]=~/^berkeley:(.+)/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'berkeley'}{$tmp[$i]}=1;
	    $bitext_refiners{'berkeley'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'berkeley'}=1;
    }
}


my @aligner_runs=(sort (keys %aligner_runs_hash));
my @bitext_aligner_runs=@aligner_runs;
my @lex_prob_aligner_runs;
my %lex_prob_refiners;
for(my $i=0; $i<@lex_prob_strategies; $i++) {
    if($lex_prob_strategies[$i]=~/^m1-m5:(.+)$/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'m1-m5'}{$tmp[$i]}=1;
	    $lex_prob_refiners{'m1-m5'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'m1-m5'}=1;
	push(@lex_prob_aligner_runs,'m1-m5');
    } elsif($lex_prob_strategies[$i]=~/^hmm:(.+)/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'hmm'}{$tmp[$i]}=1;
	    $lex_prob_refiners{'hmm'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'hmm'}=1;
	push(@lex_prob_aligner_runs,'hmm');
    } elsif($lex_prob_strategies[$i]=~/^berkeley:(.+)/) {
	my $refiner_string=$1;
	my @tmp=split(/\:/,$refiner_string);
	for(my $i=0; $i<@tmp; $i++) {
	    $refiners{'berkeley'}{$tmp[$i]}=1;
	    $lex_prob_refiners{'berkeley'}{$tmp[$i]}=1;
	}
	$aligner_runs_hash{'berkeley'}=1;
	push(@lex_prob_aligner_runs,'berkeley');
    }
}

undef @aligner_runs;
@aligner_runs=(sort (keys %aligner_runs_hash));;


if($additional_moses_parameters!~/\-alignment[= ][^ ]+/) {
    $additional_moses_parameters.=' --alignment=grow-diag-final-and';
}

$external_path = defined($dependencies_path) ? $dependencies_path : "./dependencies";

if(0 && $additional_moses_parameters=~/\-?\-parallel/) {
    $no_parallel/=2;
    $no_parallel=1 if($no_parallel<1);
    $no_parallel=~s/^([0-9]+)\..*$/$1/;
    print STDERR "no-parallel changed to $no_parallel since --parallel flag is set.\n";
}



$additional_moses_parameters=~s/ +/ /g;
$additional_moses_parameters=~s/^[\s\t]*(.*?)[\s\t]*$/$1/;


my $bitext_f="$corpus_stem.$f_suffix";
my $bitext_e="$corpus_stem.$e_suffix";

my $align_bitext_f=$bitext_f;
my $align_bitext_e=$bitext_e;
my $pos_bitext_f;
my $pos_bitext_e;
if(defined($align_corpus_stem)) {
    $align_bitext_f="$align_corpus_stem.$f_suffix";
    $align_bitext_e="$align_corpus_stem.$e_suffix";
}

if(defined($pos_corpus_stem)) {
    $pos_bitext_f="$pos_corpus_stem.$f_suffix";
    $pos_bitext_e="$pos_corpus_stem.$e_suffix";
}

my @misc_corpora=split(/\,/,$misc_corpus_string);
my @misc_background_corpora=split(/\,/,$misc_background_corpus_string);

my $corpus_errors=0;
$corpus_errors+=&compare_number_lines($align_bitext_f,$align_bitext_e);
$corpus_errors+=&compare_number_tokens($bitext_f,$align_bitext_f);
$corpus_errors+=&compare_number_tokens($bitext_e,$align_bitext_e);

my $background_bitext_f;
my $background_bitext_e;
my $align_background_bitext_f;
my $align_background_bitext_e;
my $pos_background_bitext_f;
my $pos_background_bitext_e;

if(defined($background_corpus_stem)) {
    $background_bitext_f="$background_corpus_stem.$f_suffix";
    $background_bitext_e="$background_corpus_stem.$e_suffix";
    $align_background_bitext_f=$background_bitext_f;
    $align_background_bitext_e=$background_bitext_e;
    if(defined($align_background_corpus_stem)) {
	$align_background_bitext_f="$align_background_corpus_stem.$f_suffix";
	$align_background_bitext_e="$align_background_corpus_stem.$e_suffix";
    }
    if(defined($pos_background_corpus_stem)) {
	$pos_background_bitext_f="$pos_background_corpus_stem.$f_suffix";
	$pos_background_bitext_e="$pos_background_corpus_stem.$e_suffix";
    }
    $corpus_errors+=&compare_number_lines($align_background_bitext_f,$align_background_bitext_e);
    $corpus_errors+=&compare_number_tokens($background_bitext_f,$align_background_bitext_f);
    $corpus_errors+=&compare_number_tokens($background_bitext_e,$align_background_bitext_e);
}

my $dict_bitext_f;
my $dict_bitext_e;
my $align_dict_bitext_f;
my $align_dict_bitext_e;
if(defined($dict_stem)) {
    $dict_bitext_f="$dict_stem.$f_suffix";
    $dict_bitext_e="$dict_stem.$e_suffix";
    $align_dict_bitext_f=$dict_bitext_f;
    $align_dict_bitext_e=$dict_bitext_e;
    if(defined($align_dict_stem)) {
	$align_dict_bitext_f="$align_dict_stem.$f_suffix";
	$align_dict_bitext_e="$align_dict_stem.$e_suffix";
    }
    $corpus_errors+=&compare_number_lines($align_dict_bitext_f,$align_dict_bitext_e);
    $corpus_errors+=&compare_number_tokens($dict_bitext_f,$align_dict_bitext_f);
    $corpus_errors+=&compare_number_tokens($dict_bitext_e,$align_dict_bitext_e);
}

if($corpus_errors>0) {
    print STDERR "There were a number of corpus errors. See STDERR output.\n";
    eixt(-1);
} else {
    print STDERR "All files are ok!\n";
}

my %batch_ranges;
print STDERR "num_batches=$num_batches\n";
$num_batches=&compute_batch_ranges($align_bitext_f,$align_bitext_e,\%batch_ranges,$num_batches);
foreach my $batch_id (sort (keys %batch_ranges)) {
    print STDERR "batch_ranges{$batch_id}=$batch_ranges{$batch_id}\n";
}

$mgiza_cpu/=$num_batches;
if($additional_moses_parameters=~/\-?\-parallel/) {
    $mgiza_cpu/=2;
}
$mgiza_cpu=&max(1,&truncate($mgiza_cpu));


my $corpus_size=&number_lines($align_bitext_f);

my $background_size=0;
if(defined($align_background_bitext_f)) {
    $background_size=&number_lines($align_background_bitext_f);
}

my $dict_size=0;
if(defined($align_dict_bitext_f)) {
    $dict_size=&number_lines($align_dict_bitext_f);
}

# clean up old batch directories
for(my $i=0; $i<100; $i++) {
    my $batch_id=($i<10)? "0$i" : $i;
    my $batch_dir="align_batch.$batch_id";
    if(-e "$batch_dir") {
	print STDERR "rm -rf $batch_dir\n";
	system("rm -rf $batch_dir");
    }
    if(-e "$batch_id.finished") {
	print STDERR "rm -f $batch_id.finished\n";
	system("rm -f $batch_id.finished");
    }
}


my @lines_bitext_f;
my @lines_bitext_e;
&buffer_file($align_bitext_f,\@lines_bitext_f,1);
&buffer_file($align_bitext_e,\@lines_bitext_e,1);

for(my $align_run=0; $align_run<@aligner_runs; $align_run++) {
    my $aligner=$aligner_runs[$align_run];
    print STDERR "aligner=$aligner\n";
    foreach my $batch_id (sort (keys %batch_ranges)) {
	my $batch_dir="$experiment_dir/align.$aligner/align_batch.$batch_id";
	if($use_tmpfs) {
	    system("mkdir $tmpfs_loc/$tmp_align_dir/align.$aligner");
	    $batch_dir="$tmpfs_loc/$tmp_align_dir/align.$aligner/align_batch.$batch_id";
	}

	system("mkdir $experiment_dir/align.$aligner");
	system("mkdir $batch_dir");
	print STDERR "mkdir $batch_dir\n";
	system("mkdir $batch_dir/corpus");

	open(FBATCH,">$batch_dir/corpus/batch.$f_suffix")||die("can't open $batch_dir/corpus/batch.$f_suffix: $!\n");
	open(EBATCH,">$batch_dir/corpus/batch.$e_suffix")||die("can't open $batch_dir/corpus/batch.$e_suffix: $!\n");
	my($from,$to)=split(/ /,$batch_ranges{$batch_id});
	for(my $i=$from; $i<=$to; $i++) {
	    print FBATCH $lines_bitext_f[$i];
	    print EBATCH $lines_bitext_e[$i];
	}
	if($background_size>0) {
	    open(F,"<$align_background_bitext_f")||die("can't open file $align_background_bitext_f: $!\n");
	    open(E,"<$align_background_bitext_e")||die("can't open file $align_background_bitext_e: $!\n");
	    while(defined(my $line_f=<F>) && defined(my $line_e=<E>)) {
		print FBATCH $line_f;
		print EBATCH $line_e;
	    }
	    close(F);
	    close(E);
	}
	if($dict_size>0) {
	    open(F,"<$align_dict_bitext_f")||die("can't open file $align_dict_bitext_f: $!\n");
	    open(E,"<$align_dict_bitext_e")||die("can't open file $align_dict_bitext_e: $!\n");
	    while(defined(my $line_f=<F>) && defined(my $line_e=<E>)) {
		print FBATCH $line_f;
		print EBATCH $line_e;
	    }
	    close(F);
	    close(E);
	}
    }
}

undef @lines_bitext_f;
undef @lines_bitext_e;

print STDERR "NUM_BATCHES=$num_batches\n";

if(!$skip_align) {

    my @jobs;
    my %job_ids;
    my @job_id_seq;
    for(my $i=0; $i<$num_batches; $i++) {
	my $batch_id=($i<10)? "0$i" : $i;

	print STDERR "batch_id=$batch_id\n";

	for(my $j=0; $j<@aligner_runs; $j++) {
	    my $batch_dir="$experiment_dir_full_path/align.$aligner_runs[$j]/align_batch.$batch_id";
	    if($use_tmpfs) {
		$batch_dir="$tmpfs_loc/$tmp_align_dir/align.$aligner_runs[$j]/align_batch.$batch_id";
	    }
	    my $job_id="$batch_dir/$aligner_runs[$j].$batch_id";
	    $job_id=~s/\//\_/g;

	    my $error_logfile="$batch_dir/err.$batch_id.$aligner_runs[$j].log";
	    if($ignore_word_alignment_errorlog) {
		$error_logfile='/dev/null';
	    }

	    if($aligner_runs[$j]=~/^m1-m5/) {
		my $mgiza_flag='';
		if($use_mgiza) {
		    $mgiza_flag="\-\-mgiza \-\-mgiza-cpus=$mgiza_cpu ";
		}
		push(@jobs,"nohup sh -c \'$moses_train_wrapper $moses_train_script $job_id \"--root-dir=$batch_dir --external-bin-dir=$external_path/external_binaries --corpus=$batch_dir/corpus/batch --f=$f_suffix --e=$e_suffix --first-step=1 --last-step=2 $mgiza_flag$additional_moses_parameters\" >& $error_logfile\' \&");
		push(@job_id_seq,$job_id);
		if($additional_moses_parameters=~/\-\-parallel/) {
		    $job_ids{$job_id}=2;
		} else {
		    $job_ids{$job_id}=1;
		}
	    } elsif($aligner_runs[$j]=~/^hmm/) {
		my $mgiza_flag='';
		if($use_mgiza) {
		    $mgiza_flag="\-\-mgiza \-\-mgiza-cpus=$mgiza_cpu ";
		}
		push(@jobs,"nohup sh -c \'$moses_train_wrapper $moses_train_script $job_id \"--root-dir=$batch_dir --external-bin-dir=$external_path/external_binaries --corpus=$batch_dir/corpus/batch --f=$f_suffix --e=$e_suffix --first-step=1 --last-step=2 --hmm-align $additional_moses_parameters\" >& $error_logfile\' \&");
		push(@job_id_seq,$job_id);
		if($additional_moses_parameters=~/\-\-parallel/) {
		    $job_ids{$job_id}=2;
		} else {
		    $job_ids{$job_id}=1;
		}
	    } elsif($aligner_runs[$j]=~/^berkeley/) {
#		push(@jobs,"nohup sh -c \'cd $experiment_dir_full_path/$batch_dir\; $berkeley_aligner_wrapper $berkeley_train_script $job_id \"--corpus=$experiment_dir_full_path/$batch_dir/corpus/batch --src-suffix=$f_suffix --trg-suffix=$e_suffix --work-dir=$experiment_dir_full_path/$batch_dir --experiment-dir=$experiment_dir_full_path --model1-iter=$berkeley_m1_iter --hmm-iter=$berkeley_hmm_iter --em-threads=$berkeley_em_threads\" >& $experiment_dir_full_path/$batch_dir/err.$batch_id.$aligner_runs[$j].log\' \&");
		push(@jobs,"nohup sh -c \'cd $batch_dir\; $berkeley_aligner_wrapper $berkeley_train_script $job_id \"--corpus=$batch_dir/corpus/batch --src-suffix=$f_suffix --trg-suffix=$e_suffix --external-path=$external_path/ --experiment-dir=$experiment_dir_full_path --work-dir=$batch_dir --model1-iter=$berkeley_m1_iter --hmm-iter=$berkeley_hmm_iter --em-threads=$berkeley_em_threads\" >& $error_logfile\' \&");
		push(@job_id_seq,$job_id);
		$job_ids{$job_id}=$berkeley_em_threads;
	    }
	}
    }


    my $jobs_running=0;
    my %checked;
    while(@jobs>0 || $jobs_running>0) {
	if(@jobs>0 && $jobs_running<$no_parallel) {
	    my $job=shift(@jobs);
	    my $job_id=shift(@job_id_seq);
	    print STDERR "$job\n";
	    system("$job");
	    $jobs_running+=$job_ids{$job_id};
	}

	foreach my $job_id (keys %job_ids) {
	    if(-e "$experiment_dir/$job_id.finished" && !defined($checked{"$job_id.finished"})) {
		$jobs_running-=$job_ids{$job_id};
		$checked{"$job_id.finished"}=1;
	    }
	}
	sleep(5);
    }

    foreach my $job_id (keys %job_ids) {
	if(-e "$experiment_dir/$job_id.finished") {
	    unlink("$experiment_dir/$job_id.finished");
	}
    }

    # MERGE BATCHES
    print STDERR "MERGE BATCHES.\n";
    for(my $align_run=0; $align_run<@aligner_runs; $align_run++) {

	my $aligner=$aligner_runs[$align_run];
	print STDERR "aligner=$aligner\n";

	# clean up and creation of merged dirs:
	if(-e "$experiment_dir/align.$aligner/align_all") {
	    print STDERR "rm -rf $experiment_dir/align.$aligner/align_all\n";
	    system("rm -rf $experiment_dir/align.$aligner/align_all");
	}
	print STDERR "mkdir $experiment_dir/align.$aligner/align_all\n";
	system("mkdir $experiment_dir/align.$aligner/align_all");
	print STDERR "mkdir $experiment_dir/align.$aligner/align_all/corpus\n";
	system("mkdir $experiment_dir/align.$aligner/align_all/corpus");
	print STDERR "mkdir $experiment_dir/align.$aligner/align_all/model\n";
	system("mkdir $experiment_dir/align.$aligner/align_all/model");

	if($aligner=~/(m1-m5|hmm)/) {
	    print STDERR "mkdir $experiment_dir/align.$aligner/align_all/giza.$f_suffix-$e_suffix\n";
	    system("mkdir $experiment_dir/align.$aligner/align_all/giza.$f_suffix-$e_suffix");
	    print STDERR "mkdir $experiment_dir/align.$aligner/align_all/giza.$e_suffix-$f_suffix\n";
	    system("mkdir $experiment_dir/align.$aligner/align_all/giza.$e_suffix-$f_suffix");
	} elsif($aligner=~/berkeley/) {
	    print STDERR "mkdir $experiment_dir/align.$aligner/refined.nil\n";
	    system("mkdir $experiment_dir/align.$aligner/refined.nil");
	    print STDERR "mkdir $experiment_dir/align.$aligner/refined.nil/model\n";
	    system("mkdir $experiment_dir/align.$aligner/refined.nil/model");
	}

	my $align_format;
	if($aligner=~/(m1-m5|hmm)/) {
	    my $batch_dir="$experiment_dir/align.$aligner/align_batch.00";
	    if($use_tmpfs) {
		$batch_dir="$tmpfs_loc/$tmp_align_dir/align.$aligner/align_batch.00";
	    }

	    opendir(M,"$batch_dir/giza.$f_suffix-$e_suffix");
	    while(defined(my $file=readdir(M))) {
		if($file=~/^$f_suffix-$e_suffix\.(.+(?:final|hmm\.[0-9]+)).gz$/) {
		    $align_format=$1;
		    last;
		}
	    }
	    closedir(M);
	    print STDERR "giza-alignment=$align_format\n";
	}

	my $last_sent_id=0;
	my @aligned_buffer;
	$last_sent_id=&combine_aligned_file(\@aligned_buffer,$aligner,$align_format,$f_suffix,$e_suffix,\%batch_ranges,$num_batches,$last_sent_id);
	my($first_batch_corpus_from,$first_batch_corpus_to)=split(/ /,$batch_ranges{'00'});
	$last_sent_id=&add_aligned_slice_file(\@aligned_buffer,$aligner,$align_format,$f_suffix,$e_suffix,$first_batch_corpus_to+1,$first_batch_corpus_to+$background_size,$last_sent_id);
	$last_sent_id=&add_aligned_slice_file(\@aligned_buffer,$aligner,$align_format,$f_suffix,$e_suffix,$first_batch_corpus_to+$background_size+1,$first_batch_corpus_to+$background_size+$dict_size,$last_sent_id);
	if($aligner=~/(m1-m5|hmm)/) {
	    &write_buffer_to_file(\@aligned_buffer,"$experiment_dir/align.$aligner/align_all/giza.$f_suffix-$e_suffix/$f_suffix-$e_suffix.$align_format.gz");
	} elsif($aligner=~/berkeley/) {
	    &write_buffer_to_file(\@aligned_buffer,"$experiment_dir/align.$aligner/refined.nil/model/aligned.nil");
	}
	undef @aligned_buffer;

	$last_sent_id=0;
	$last_sent_id=&combine_aligned_file(\@aligned_buffer,$aligner,$align_format,$e_suffix,$f_suffix,\%batch_ranges,$num_batches,$last_sent_id);
	($first_batch_corpus_from,$first_batch_corpus_to)=split(/ /,$batch_ranges{'00'});
	$last_sent_id=&add_aligned_slice_file(\@aligned_buffer,$aligner,$align_format,$e_suffix,$f_suffix,$first_batch_corpus_to+1,$first_batch_corpus_to+$background_size,$last_sent_id);
	$last_sent_id=&add_aligned_slice_file(\@aligned_buffer,$aligner,$align_format,$e_suffix,$f_suffix,$first_batch_corpus_to+$background_size+1,$first_batch_corpus_to+$background_size+$dict_size,$last_sent_id);
	if($aligner=~/(m1-m5|hmm)/) {
	    &write_buffer_to_file(\@aligned_buffer,"$experiment_dir/align.$aligner/align_all/giza.$e_suffix-$f_suffix/$e_suffix-$f_suffix.$align_format.gz");
	}
	undef @aligned_buffer;

	my @lines_bitext_f;
	&buffer_file($bitext_f,\@lines_bitext_f,0);
	if($background_size>0) {
	    &buffer_file($background_bitext_f,\@lines_bitext_f,0);
	}
	if($dict_size>0) {
	    &buffer_file($dict_bitext_f,\@lines_bitext_f,0);
	}
	&write_buffer_to_file(\@lines_bitext_f,"$experiment_dir/align.$aligner/align_all/corpus/word_aligned.$f_suffix");
	undef @lines_bitext_f;
	my @lines_bitext_e;
	&buffer_file($bitext_e,\@lines_bitext_e,0);
	if($background_size>0) {
	    &buffer_file($background_bitext_e,\@lines_bitext_e,0);
	}
	if($dict_size>0) {
	    &buffer_file($dict_bitext_e,\@lines_bitext_e,0);
	}
	&write_buffer_to_file(\@lines_bitext_e,"$experiment_dir/align.$aligner/align_all/corpus/word_aligned.$e_suffix");
	undef @lines_bitext_e;
    }
#end of skip align:

    if($use_tmpfs && $clean_up) {
	system("rm -rf $tmpfs_loc/$tmp_align_dir");
    }

}


print STDERR "Build additional refinements for lexical translations.\n";
my @jobs;
my %job_ids;
system("mkdir $experiment_dir/models");
system("mkdir $experiment_dir/models/model");

for(my $align_run=0; $align_run<@aligner_runs; $align_run++) {
    my $aligner=$aligner_runs[$align_run];

    next if($aligner=~/berkeley/);

    foreach my $refinement_strategy (keys %{ $refiners{$aligner} }) {
	my $job_id="$aligner.$refinement_strategy";

	system("mkdir $experiment_dir/align.$aligner/refined.$refinement_strategy");
	system("mkdir $experiment_dir/align.$aligner/refined.$refinement_strategy/corpus");
	system("mkdir $experiment_dir/align.$aligner/refined.$refinement_strategy/model");

	system("cp $experiment_dir/align.$aligner/align_all/corpus/word_aligned.* $experiment_dir/align.$aligner/refined.$refinement_strategy/corpus");

#	system("cp $experiment_dir/align.$aligner/align_all/corpus/bitext_link.$f_suffix $experiment_dir/models/model/aligned.$f_suffix");
#	system("cp $experiment_dir/align.$aligner/align_all/corpus/bitext_link.$e_suffix $experiment_dir/models/model/aligned.$e_suffix");

	if($aligner=~/(m1-m5|hmm)/) {
	    system("cp -r $experiment_dir/align.$aligner/align_all/giza.* $experiment_dir/align.$aligner/refined.$refinement_strategy/");
	}

	if($refinement_strategy=~/^((grow-diag(-final)?(-and)?)|intersect|union)$/) {
	    my $hmm_flag='';
	    if($aligner=~/hmm/) {
		$hmm_flag='--hmm-align';
	    }
#	    push(@jobs,"nohup sh -c \'$moses_train_wrapper $moses_train_script $job_id \"--root-dir=$experiment_dir/align.$aligner/refined.$refinement_strategy --external-bin-dir=$external_path/external_binaries --corpus=$experiment_dir/align.$aligner/refined.$refinement_strategy/corpus/$corpus_stem --f=$f_suffix --e=$e_suffix --first-step=3 --last-step=3 $hmm_flag --alignment=$refinement_strategy\" >& $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");

# substitute word_aligned for corpus stem:

	    push(@jobs,"nohup sh -c \'$moses_train_wrapper $moses_train_script $job_id \"--root-dir=$experiment_dir/align.$aligner/refined.$refinement_strategy --external-bin-dir=$external_path/external_binaries --corpus=$experiment_dir/align.$aligner/refined.$refinement_strategy/corpus/word_aligned --f=$f_suffix --e=$e_suffix --first-step=3 --last-step=3 $hmm_flag --alignment=$refinement_strategy\" >& $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");


	} elsif($aligner=~/berkeley/ && $refinement_strategy eq 'nil') {
	    system("cp $experiment_dir/align.$aligner/align_all/model/aligned.berkeley $experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy");
	    next;
	} elsif($refinement_strategy=~/^(e2f)$/) {
	    if($aligner=~/hmm/) {
		push(@jobs,"nohup sh -c \'build/bitext_models/scripts/convert-giza-format-to-aligned.pl $experiment_dir/align.$aligner/align_all/giza.$e_suffix-$f_suffix/$e_suffix-$f_suffix.Ahmm.5.gz e-f $job_id $experiment_dir 1> $experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy 2> $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");
	    } elsif($aligner=~/m1-m5/) {
		push(@jobs,"nohup sh -c \'build/bitext_models/scripts/convert-giza-format-to-aligned.pl $experiment_dir/align.$aligner/align_all/giza.$e_suffix-$f_suffix/$e_suffix-$f_suffix.A3.final.gz e-f $job_id $experiment_dir 1> $experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy 2> $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");
	    }
	} elsif($refinement_strategy=~/^(f2e)$/) {
	    if($aligner=~/hmm/) {
		push(@jobs,"nohup sh -c \'build/bitext_models/scripts/convert-giza-format-to-aligned.pl $experiment_dir/align.$aligner/align_all/giza.$f_suffix-$e_suffix/$f_suffix-$e_suffix.Ahmm.5.gz f-e $job_id $experiment_dir 1> $experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy 2> $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");
	    } elsif($aligner=~/m1-m5/) {
		push(@jobs,"nohup sh -c \'build/bitext_models/scripts/convert-giza-format-to-aligned.pl $experiment_dir/align.$aligner/align_all/giza.$f_suffix-$e_suffix/$f_suffix-$e_suffix.A3.final.gz f-e $job_id $experiment_dir 1> $experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy 2> $experiment_dir/align.$aligner/refined.$refinement_strategy/err.log\' \&");
	    }
	}

	$job_ids{$job_id}=1;
    }
}

my $jobs_running=0;
my %checked;
while(@jobs>0 || $jobs_running>0) {
    if(@jobs>0 && $jobs_running<$no_parallel) {
	my $job=shift(@jobs);
	print STDERR "$job\n";
	system("$job");
	$jobs_running++;
    }

    foreach my $job_id (keys %job_ids) {
	if(-e "$experiment_dir/$job_id.finished" && !defined($checked{"$job_id.finished"})) {
	    $jobs_running--;
	    $checked{"$job_id.finished"}=1;
	}
    }
    sleep(5);
}


foreach my $job_id (keys %job_ids) {
    if(-e "$experiment_dir/$job_id.finished") {
	unlink("$experiment_dir/$job_id.finished");
    }
}

if($clean_up) {
    print STDERR "Cleaning up...\n";
    for(my $align_run=0; $align_run<@aligner_runs; $align_run++) {
	my $aligner=$aligner_runs[$align_run];
	for(my $i=0; $i<$num_batches; $i++) {
	    my $batch_id=($i<10)? "0$i" : $i;
	    my $batch_dir="$experiment_dir/align.$aligner/align_batch.$batch_id";
	    if(-e "$batch_dir") {
		print STDERR "rm -rf $batch_dir\n";
		system("rm -rf $batch_dir");
	    }
	}
    }
    print STDERR "done.\n";
}

print STDERR "Build lexical translations.\n";
system("mkdir $experiment_dir/lex_trans");
system("mkdir $experiment_dir/lex_trans/model");
system("mkdir $experiment_dir/lex_trans/corpus");
my @lines_lex_bitext_f;
my @lines_lex_bitext_e;
my @lines_lex_bitext_a;
my @lines_pos_bitext_f;
my @lines_pos_bitext_e;
my @lines_misc_text;

for(my $align_run=0; $align_run<@aligner_runs; $align_run++) {
    my $aligner=$aligner_runs[$align_run];
    foreach my $refinement_strategy (keys %{ $refiners{$aligner} }) {
	# f:
	&buffer_file($bitext_f,\@lines_lex_bitext_f,0);
	if(defined($pos_bitext_f)) {
	    &buffer_file($pos_bitext_f,\@lines_pos_bitext_f,0);
	}
	if($background_size>0) {
	    &buffer_file($background_bitext_f,\@lines_lex_bitext_f,0);
	    if(defined($pos_background_bitext_f)) {
		&buffer_file($pos_background_bitext_f,\@lines_pos_bitext_f,0);
	    }
	}
	if($dict_size>0) {
	    &buffer_file($dict_bitext_f,\@lines_lex_bitext_f,0);
	}

	# e:
	&buffer_file($bitext_e,\@lines_lex_bitext_e,0);
	if(defined($pos_bitext_e)) {
	    &buffer_file($pos_bitext_e,\@lines_pos_bitext_e,0);
	}
	if($background_size>0) {
	    &buffer_file($background_bitext_e,\@lines_lex_bitext_e,0);
	    if(defined($pos_background_bitext_e)) {
		&buffer_file($pos_background_bitext_e,\@lines_pos_bitext_e,0);
	    }
	}
	if($dict_size>0) {
	    &buffer_file($dict_bitext_e,\@lines_lex_bitext_e,0);
	}
	# refined alignments:
	&buffer_file("$experiment_dir/align.$aligner/refined.$refinement_strategy/model/aligned.$refinement_strategy",\@lines_lex_bitext_a,0);

	for(my $i=0; $i<@misc_corpora; $i++) {
	    &buffer_file($misc_corpora[$i],\@{ $lines_misc_text[$i] },0);
	    if($background_size>0) {
		&buffer_file($misc_background_corpora[$i],\@lines_misc_text,0);
	    }
	}
    }
}
&write_buffer_to_file(\@lines_lex_bitext_f,"$experiment_dir/lex_trans/corpus/lex_aligned.$f_suffix");
undef @lines_lex_bitext_f;
&write_buffer_to_file(\@lines_lex_bitext_e,"$experiment_dir/lex_trans/corpus/lex_aligned.$e_suffix");
undef @lines_lex_bitext_e;
&write_buffer_to_file(\@lines_lex_bitext_a,"$experiment_dir/lex_trans/model/aligned.grow-diag-final");
undef @lines_lex_bitext_a;

if(defined($pos_bitext_f)) {
    &write_buffer_to_file(\@lines_pos_bitext_f,"$experiment_dir/models/model/aligned_pos.$f_suffix");
    undef @lines_pos_bitext_f;
}
if(defined($pos_bitext_e)) {
    &write_buffer_to_file(\@lines_pos_bitext_e,"$experiment_dir/models/model/aligned_pos.$e_suffix");
    undef @lines_pos_bitext_e;
}

for(my $i=0; $i<@misc_corpora; $i++) {
    my($corpus_name)=$misc_corpora[$i]=~/([^\/]+)$/;
    &write_buffer_to_file(\@{ $lines_misc_text[$i] },"$experiment_dir/models/model/aligned_misc.$corpus_name");
    undef @{ $lines_misc_text[$i] };
}



#my $call_lex_prob="$moses_train_script --root-dir=$experiment_dir/lex_trans --external-bin-dir=$external_path/external_binaries --corpus=$experiment_dir/lex_trans/corpus/lex_aligned --f=$f_suffix --e=$e_suffix --first-step=4 --last-step=4 --alignment=grow-diag-final >& $experiment_dir/err.lex_prob.log";
#print STDERR "$call_lex_prob\n";
#system($call_lex_prob);

#my $clean_lex_f2e_call="cat $experiment_dir/lex_trans/model/lex.f2e | $external_path/build/bitext_models/scripts/remove-moses-zero-lex-prob-entries.pl 1> $experiment_dir/lex_trans/model/lex.f2e.clean";
#print STDERR "$clean_lex_f2e_call\n";
#system($clean_lex_f2e_call);
#system("mv $experiment_dir/lex_trans/model/lex.f2e.clean $experiment_dir/models/model/lex.f2e");

#my $clean_lex_e2f_call="cat $experiment_dir/lex_trans/model/lex.e2f | build/bitext_models/scripts/remove-moses-zero-lex-prob-entries.pl 1> $experiment_dir/lex_trans/model/lex.e2f.clean";
#print STDERR "$clean_lex_e2f_call\n";
#system($clean_lex_e2f_call);
#system("mv $experiment_dir/lex_trans/model/lex.e2f.clean  $experiment_dir/models/model/lex.e2f");



# NEXT:
system("mkdir $experiment_dir/models/corpus/");
system("cp $experiment_dir/lex_trans/corpus/lex_aligned.$f_suffix $experiment_dir/models/corpus/bitext.$f_suffix");
system("cp $experiment_dir/lex_trans/corpus/lex_aligned.$e_suffix $experiment_dir/models/corpus/bitext.$e_suffix");
system("cp $experiment_dir/lex_trans/model/aligned.grow-diag-final $experiment_dir/models/model/aligned.grow-diag-final");
system("cp $experiment_dir/lex_trans/corpus/lex_aligned.$f_suffix $experiment_dir/models/model/aligned.$f_suffix");
system("cp $experiment_dir/lex_trans/corpus/lex_aligned.$e_suffix $experiment_dir/models/model/aligned.$e_suffix");

if($clean_up) {
    print STDERR "rm -rf $experiment_dir/lex_trans\n";
    system("rm -rf $experiment_dir/lex_trans");
}


if($clean_up) {
    	my $call="rm -rf $experiment_dir/dm/corpus";
	print STDERR "$call\n";
	system($call);
	$call="rm -rf $experiment_dir/dm/model";
	print STDERR "$call\n";
	system($call);
	$call="rm -rf $experiment_dir/dm/moses-extract/model/extract.100.gz";
	print STDERR "$call\n";
	system($call);
	$call="rm -rf $experiment_dir/models/corpus";
	print STDERR "$call\n";
	system($call);
	$call="rm -rf $experiment_dir/models/model/extract.inv.sorted.gz";
	print STDERR "$call\n";
	system($call);
}

sub determine_phrasetable_format {
    my($phrase_table)=@_;

    if($phrase_table=~/\.gz$/o) {
	open F, "<:gzip", $phrase_table, or die("can't open $phrase_table: $!\n");
    } else {
	open(F,"<$phrase_table") || die("can't open $phrase_table: $!\n");
    }

    my $format='undef';
    my $c=0;
    while(defined(my $line=<F>)) {
	chomp($line);
	$c++;
	last if($c>50);
	my @entries=split(/ \|\|\| /,$line);
	if(@entries==5) {
	    if($entries[2]=~/^[ 0-9\.e\-]+$/
	       && $entries[3]=~/^[0-9]+\-[0-9]+/
	       && $entries[4]=~/[0-9]+ [0-9]+ [0-9]+$/) {
		$format='f_e_p_a_c';
		last;
	    } elsif($entries[2]=~/^[ \(\)0-9\,]+$/
		    && $entries[3]=~/^[ \(\)0-9\,]+$/
		    && $entries[4]=~/^[ 0-9\.e\-]+$/) {
		$format='f_e_af_ae_p';
		last;
	    }
	}
    }
    close(F);
    return $format;
}



sub compare_number_lines {
    my($text1,$text2)=@_;

    if($text1 eq $text2) {
	return 0;
    }

    my $num_lines_text1=0;
    open(F,"<$text1")||die("can't open file $text1: $!\n");
    while(defined(my $line=<F>)) {
	$num_lines_text1++;
    }
    close(F);

    my $num_lines_text2=0;
    open(F,"<$text2")||die("can't open file $text2: $!\n");
    while(defined(my $line=<F>)) {
	$num_lines_text2++;
    }
    close(F);

    if($num_lines_text1==$num_lines_text2) {
	return 0;
    } else {
	print STDERR "num_lines(\'$text1\')=$num_lines_text1\n";
	print STDERR "num_lines(\'$text2\')=$num_lines_text2\n";
	return 1;
    }
}


sub compare_number_tokens {
    my($text1,$text2)=@_;
    if($text1 eq $text2) {
	return 0;
    }

    my $num_lines_text=0;
    open(F,"<$text1")||die("can't open file $text1: $!\n");
    open(G,"<$text2")||die("can't open file $text2: $!\n");
    my $error=0;
    while(defined(my $line1=<F>) && defined(my $line2=<G>)) {
	chomp($line1);
	my @tokens1=split(/ /,$line1);
	chomp($line2);
	my @tokens2=split(/ /,$line2);
	$num_lines_text++;
	if(@tokens1!=@tokens2) {
	    my $num_tokens1=@tokens1;
	    my $num_tokens2=@tokens2;
	    print STDERR "ERROR in line $num_lines_text:\n";
	    print STDERR "file \'$text1\ ($num_tokens1 tokens)': $line1\n";
	    print STDERR "file \'$text2\ ($num_tokens2 tokens)': $line2\n";
	    $error++;
	}
    }
    close(F);
    close(G);

    return $error;
}

sub compute_batch_ranges {
    my($bitext_f,$_bitext_e,$batch_ranges,$num_batches)=@_;

    my $total_size=0;
    my $total_lines=0;
    open(F,"<$bitext_f")||die("can't open file $bitext_f: $!\n");
    open(E,"<$bitext_e")||die("can't open file $bitext_e: $!\n");
    while(defined(my $line_f=<F>) && defined(my $line_e=<E>)) {
	chomp($line_f);
	my @tokens_f=split(/ /,$line_f);
	my $num_tokens_f=@tokens_f;
	chomp($line_e);
	my @tokens_e=split(/ /,$line_e);
	my $num_tokens_e=@tokens_e;
	$total_size+=$num_tokens_f*$num_tokens_e;
	$total_lines++;
    }
    close(F);
    close(E);

    my $avg_batch_size=$total_size/$num_batches;
    my $current_size=0;
    my $from_line=0;
    my $to_line=0;
    my $line=0;

    my $c=0;
    open(F,"<$bitext_f")||die("can't open file $bitext_f: $!\n");
    open(E,"<$bitext_e")||die("can't open file $bitext_e: $!\n");
    while(defined(my $line_f=<F>) && defined(my $line_e=<E>)) {
	chomp($line_f);
	$line++;
	my @tokens_f=split(/ /,$line_f);
	my $num_tokens_f=@tokens_f;
	chomp($line_e);
	my @tokens_e=split(/ /,$line_e);
	my $num_tokens_e=@tokens_e;
	$current_size+=$num_tokens_f*$num_tokens_e;
	if($current_size>=$avg_batch_size || $line==$total_lines) {
	    $from_line=$to_line+1;
	    $to_line=$line;
	    my $batch_id=($c<10)? "0$c" : $c;
	    $$batch_ranges{$batch_id}="$from_line $to_line";
	    $current_size=0;
	    $c++;
	}
    }
    close(F);
    close(E);

    return $c;
}

sub number_lines {
    my($text)=@_;

    my $num_lines_text=0;
    open(F,"<$text")||die("can't open file $text: $!\n");
    while(defined(my $line=<F>)) {
	$num_lines_text++;
    }
    close(F);

    return $num_lines_text;
}


sub buffer_file {
    my($file,$buffer,$offset)=@_;
    for(my $i=0; $i<$offset; $i++) {
	push(@$buffer,"");
    }
    open(F,"<$file")||die("can't open file $file: $!\n");
    while(defined(my $line=<F>)) {
	push(@$buffer,$line);
    }
    close(F);
}

sub buffer_file_dm_bitext {
    my($file,$buffer,$last_sent_id,$add_sent_tags)=@_;
    $add_sent_tags||=0;

    open(F,"<$file")||die("can't open file $file: $!\n");
    while(defined(my $line=<F>)) {
	chomp($line);
	$last_sent_id++;
	my @tokens=split(/ /,$line);
	if($add_sent_tags) {
	    unshift(@tokens,'<s>');
	    push(@tokens,'</s>');
	}
	for(my $i=0; $i<@tokens; $i++) {
	    $tokens[$i]="$i:$tokens[$i]";
	}
	my $position_line=join(' ',@tokens) . "\n";;
	push(@$buffer,"<sent_id=$last_sent_id>\n");
	push(@$buffer,$position_line);
	push(@$buffer,"<\/sent_id>\n");
    }
    close(F);
    return $last_sent_id;
}

sub buffer_file_dm_alignment {
    my($file_f,$file_e,$file_a,$buffer,$start_dict)=@_;
    my $sent_id=0;

    open(F,"<$file_f")||die("can't open file $file_f: $!\n");
    open(E,"<$file_e")||die("can't open file $file_e: $!\n");
    open(A,"<$file_a")||die("can't open file $file_a: $!\n");
    while(defined(my $line_f=<F>) && defined(my $line_e=<E>) && defined(my $line_a=<A>)) {
	chomp($line_f);
	chomp($line_e);
	chomp($line_a);
	$sent_id++;
	if($sent_id<$start_dict) {
	    my @tokens_f=split(/ /,$line_f);
	    my $f_end=@tokens_f+1;
	    my @tokens_e=split(/ /,$line_e);
	    my $e_end=@tokens_e+1;
	    my @tokens_a=split(/ /,$line_a);
	    for(my $i=0; $i<@tokens_a; $i++) {
		my($f_index,$e_index)=split(/\-/,$tokens_a[$i]);
		$f_index++;
		$e_index++;
		$tokens_a[$i]="$f_index\-$e_index";
	    }
	    unshift(@tokens_a,'0-0');
	    push(@tokens_a,"$f_end\-$e_end");
	    $line_a=join(' ',@tokens_a);
	}

	push(@$buffer,"0-0\n");
	push(@$buffer,"$line_a\n");
	push(@$buffer,"0-0\n");
    }
    close(F);
}





sub write_buffer_to_file {
    my($buffer,$file)=@_;

    if($file=~/\.gz$/o) {
        open F, ">:gzip", $file, or die("can't open $file: $!\n");
    } else {
        open(F,">$file") || die("can't open $file: $!\n");
    }

    for(my $i=0; $i<@$buffer; $i++) {
	print F $buffer->[$i];
    }
    close(F);
}


sub combine_aligned_file {
    my($aligned_buffer,$aligner,$align_format,$f_suffix,$e_suffix,$batch_ranges,$num_batches,$last_sent_id)=@_;

    for(my $i=0; $i<$num_batches; $i++) {
	my $batch_id=($i<10)? "0$i" : $i;
	my($from,$to)=split(/ /,$$batch_ranges{$batch_id});

	my $batch_dir="$experiment_dir_full_path/align.$aligner/align_batch.$batch_id";
	if($use_tmpfs) {
	    $batch_dir="$tmpfs_loc/$tmp_align_dir/align.$aligner/align_batch.$batch_id";
	}

	if($aligner=~/^(m1-m5|hmm)/) {
	    my $align_file="$batch_dir/giza.$f_suffix-$e_suffix/$f_suffix-$e_suffix\.$align_format\.gz";
	    open(F,"<:gzip","$align_file")||die("can't open file $align_file: $!\n");
	    while(defined(my $line=<F>)) {
		if($line=~/^\# Sentence pair \(([0-9]+)\) source length (.+)\n/) {
		    my $sent_id=$1;
		    my $rest=$2;
		    my $sent_id_adjusted=$from+$sent_id-1;

		    if($sent_id_adjusted<$from || $sent_id_adjusted>$to) {
			last;
		    }
		    my $line_adjusted="\# Sentence pair \($sent_id_adjusted\) source length $rest\n";
		    for(my $s=$last_sent_id+1; $s<$sent_id_adjusted; $s++) {
			my $insert_line="\# Sentence pair ($s) source length 1 target length 1 alignment score : 0\nNIL\nNULL \(\{ \}\)\n";
			push(@$aligned_buffer,$insert_line);
		    }
		    my $align_line=$line_adjusted;
		    $line=<F>;
		    $align_line.=$line;
		    $line=<F>;
		    $align_line.=$line;
		    push(@$aligned_buffer,$align_line);
		    $last_sent_id=$sent_id_adjusted;
		} else {
		    print STDERR "Error in file: $align_file\n  line=$line";
		}
	    }
	    close(F);
	    for(my $s=$last_sent_id+1; $s<=$to; $s++) {
		my $insert_line="\# Sentence pair ($s) source length 1 target length 1 alignment score : 0\nNIL\nNULL \(\{ \}\)\n";
		push(@$aligned_buffer,$insert_line);
		$last_sent_id=$s;
	    }
	} elsif($aligner=~/^berkeley/) {
	    my $align_file="$batch_dir/output/training.align";
	    open(F,"<$align_file")||die("can't open file $align_file: $!\n");
	    while(defined(my $line=<F>)) {
		chomp($line);
		$last_sent_id++;
		if($last_sent_id<$from) {
		    next;
		} elsif($last_sent_id>$to) {
		    $last_sent_id--;
		    last;
		} else {
		    my $sorted_line=&sort_align_links($line);
		    push(@$aligned_buffer,"$sorted_line\n");
		}
	    }
	}
    }
    return $last_sent_id;
}

sub add_aligned_slice_file {
    my($aligned_buffer,$aligner,$align_format,$f_suffix,$e_suffix,$from,$to,$last_sent_id)=@_;
    print STDERR "from=$from to=$to\n";

    my $batch_dir="$experiment_dir_full_path/align.$aligner/align_batch.00";
    if($use_tmpfs) {
	$batch_dir="$tmpfs_loc/$tmp_align_dir/align.$aligner/align_batch.00";
    }

    if($aligner=~/^(m1-m5|hmm)/) {
	my $align_file="$batch_dir/giza.$f_suffix-$e_suffix/$f_suffix-$e_suffix\.$align_format\.gz";
	open(F,"<:gzip","$align_file")||die("can't open file $align_file: $!\n");
	while(defined(my $line=<F>)) {
	    if($line=~/^\# Sentence pair \(([0-9]+)\) source length (.+)\n/) {
		my $sent_id=$1;
		my $rest=$2;
		if($sent_id>=$from && $sent_id<=$to) {
		    $last_sent_id++;
		    my $line_adjusted="\# Sentence pair \($last_sent_id\) source length $rest\n";
		    my $align_line=$line_adjusted;
		    $line=<F>;
		    $align_line.=$line;
		    $line=<F>;
		    $align_line.=$line;
		    push(@$aligned_buffer,$align_line);
		} elsif($sent_id>$to) {
		    last;
		}
	    }
	}
	close(F);
    } elsif($aligner=~/^berkeley/) {
	my $align_file="$batch_dir/output/training.align";
	my $sent_id=0;
	open(F,"<$align_file")||die("can't open file $align_file: $!\n");
	while(defined(my $line=<F>)) {
	    chomp($line);
	    $sent_id++;
	    if($sent_id>=$from && $sent_id<=$to) {
		$last_sent_id++;
		my $sorted_line=&sort_align_links($line);
		push(@$aligned_buffer,"$sorted_line\n");
	    } elsif($sent_id>$to) {
		last;
	    }
	}
	close(F);
    }
    return $last_sent_id;
}



sub sort_align_links {
    my($line)=@_;
    my @align_pairs=split(/ /,$line);
    my %f2e_links;
    for(my $i=0; $i<@align_pairs; $i++) {
	my($f_index,$e_index)=split(/\-/,$align_pairs[$i]);
	$f2e_links{$f_index}{$e_index}=1;
    }
    my @sorted_align_pairs;
    foreach my $f_index (sort {$a<=>$b} (keys %f2e_links)) {
	foreach my $e_index (sort {$a<=>$b} (keys %{ $f2e_links{$f_index} })) {
	    push(@sorted_align_pairs,"$f_index\-$e_index");
	}
    }
    return join(' ',@sorted_align_pairs);
}


sub truncate {
    my($num)=@_;
    $num=sprintf("%.1f",$num);
    $num=~s/\.[0-9]+$//;
    return $num;
}

sub max {
    return $_[0] if($_[0]>$_[1]);
    return $_[1];
}
