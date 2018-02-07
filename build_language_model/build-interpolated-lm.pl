#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long "GetOptions";
use File::Spec::Functions;

my $arg_string=join(' ',@ARGV);
my $command=$0;

print STDERR "\ncall: $command $arg_string\n\n";
my $pid=$$;
my $clean_up=1;


# example call:
# smt5:/glusterfs/volume0/christof/mt/buildpt/lm
# /home/christof/code/oister/build/language_models/scripts/build-interpolated-lm.pl --input-corpora=1-1-1:kn:bitext.en,background.en --order=3 --lm=foo.lm --ext-path=/home/christof/code/oister/install/external_components/ --num-parallel=2 --ppl=/home/ilps/smt/data/translation_test/OpenMT/mt06gale/arabic-english/mt06gale.arabic-english.ref.tok.txt.0 --input-lms=/home/christof/ilps-christof/mt/experiments/german/test-dev/data/europarl.srilm --delete-builds

BEGIN {
    if(!defined($ENV{'OISTERHOME'})
       || $ENV{'OISTERHOME'} eq '') {
        print STDERR "environment variable OISTERHOME must be set:\n";
        print STDERR "export OISTERHOME=/path/to/oister/distribution\n";
        exit(-1);
    }
}

BEGIN {
    my $release_info=`cat /etc/*-release`;
    $release_info=~s/\n/ /g;
    my $os_release;
    if($release_info=~/CentOS release 5\./) {
        $os_release='CentOS_5';
    } elsif($release_info=~/CentOS release 6\./) {
        $os_release='CentOS_6';
    }
    if($os_release eq 'CentOS_6') {
        unshift @INC, $ENV{"OISTERHOME"}."/lib/perl_modules/lib64/perl5"
    } else {
        unshift @INC, $ENV{"OISTERHOME"}."/resources/bin/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi"
    }
}

use PerlIO::gzip;

my $OISTERHOME=$ENV{'OISTERHOME'};

my $_HELP;
my $corpora_tuples_list;
my $lm_file;
my $lm_list;
my $batch_size=1000000;
my $external_path;
my $min_counts_string='1-1-1-2-2';
my $order=5;
my $smoothing='kndiscount';
my $no_interpolation=0;
my $keep_files=0;
my $working_dir='working_dir';
my $preprocessing_flags='lc,numsub,dedupl,sent_tags';
my $binary_lm;
my $num_parallel=1;
my $ppl_file;
my $delete_builds=0;

$_HELP = 1
    unless &GetOptions(
  "input-corpora=s" => \$corpora_tuples_list,
  "input-lms=s" => \$lm_list,
  "batch-size|b=i" => \$batch_size,
  "external-path|ext-path=s" => \$external_path,
  "lm=s" => \$lm_file,
  "num-parallel=i" => \$num_parallel,
  "binary-lm|bin-lm" => \$binary_lm,
  "order=i" => \$order,
  "delete-builds" => \$delete_builds,
  "ppl=s" => \$ppl_file,
  "min-counts=s" => \$min_counts_string,
  "smoothing|s=s" => \$smoothing,
  "pre-processing|pre-proc=s" => \$preprocessing_flags,
  "working-dir|work-dir=s" => \$working_dir,
  "no-interpolation" => \$no_interpolation,
  "keep-files" => \$keep_files,
  "help|h" => \$_HELP
    );

if(!defined($corpora_tuples_list) && !defined($lm_list)) {
    $_HELP=1;
}
    
if(!defined($external_path)) {
    print STDERR "  --external-path=str must be set\n";
    $_HELP=1;
}
   
if($_HELP) {
    &print_help();
    exit(-1);
}


if(!defined($lm_file)) {
    print STDERR "Warning: No interpolation will be carried out. --lm is not specified.\n";
    print STDERR "Only building of models will be carried out.\n";
}


print STDERR "Unprocessed by Getopt::Long\n" if $ARGV[0];
foreach (@ARGV) {
    print STDERR "$_\n";
}

my $current_dir=File::Spec->rel2abs('.');
print STDERR "current directory=$current_dir\n\n";

if(defined($lm_file) && -e "$lm_file") {
    print STDERR "Error: LM file \"$lm_file\" exists. Change name or remove\n";
    exit(-1);
}

my $srilm_bin="$external_path/external_binaries/srilm/";
my $srilm_bin_machinetype="$external_path/external_binaries/srilm/bin_machine_type";

my $PATH=$ENV{'PATH'};
$ENV{'PATH'}="$PATH:$srilm_bin:$srilm_bin_machinetype";
#print STDERR "ENV{'PATH'}=$ENV{'PATH'}\n";

my @jobs_tbd;
my $job_counter=0;
my(@corpora_tuples)=split(/\,/,$corpora_tuples_list);
for(my $i=0; $i<@corpora_tuples; $i++) {
    my $min_counts;
    my $smoothing_lm;
    my $text_file='NO FILE PROVIDED';
    my(@parts)=split(/\:/,$corpora_tuples[$i]);
    if(@parts==3) {
	$min_counts=$parts[0];
	$smoothing_lm=$parts[1];
	$text_file=$parts[2];
    } elsif(@parts==2) {
	if($parts[0]=~/^[0-9]/) {
	    $min_counts=$parts[0];
	} elsif($parts[0]=~/^(kn|kneser-ney|kndiscount|wb|witteb-bell|wbdiscount)$/) {
	    $smoothing_lm=$parts[0];
	}
	$text_file=$parts[1];
    } elsif(@parts==1) {
	$text_file=$parts[0];
    } else {
	print STDERR "Error could not parse input tuple: \"$corpora_tuples[$i]\"\n";
	exit(-1);
    }

    if(defined($min_counts) && $min_counts!~/^[0-9]+(\-[0-9]+)*$/) {
	print STDERR "Error could not parse input tuple: \"$corpora_tuples[$i]\"\n";
	exit(-1);
    }

    if(!( -e "$text_file")) {
	print STDERR "Error: file \"$text_file\" cannot be found.\n";
	exit(-1);
    }

    $min_counts=$min_counts_string if(!defined($min_counts));
    $smoothing_lm=$smoothing if(!defined($smoothing_lm));
    $text_file=File::Spec->rel2abs($text_file);
    my($text_file_name)=$text_file=~/^.*?([^\/]+)$/;
    my $corpus_lm_file="$current_dir/$text_file_name.$job_counter.lm";
    $corpus_lm_file=File::Spec->rel2abs($corpus_lm_file);

    if(-e $corpus_lm_file && !(-z "$corpus_lm_file")) {
	print STDERR "Error: LM file \"$corpus_lm_file\" already exists. Change name or remove.\n";
	exit(-1);
    }

    my $build_dir="$current_dir/build\_$job_counter";
    my $job_call="mkdir $build_dir\; cd $build_dir\; nohup sh -c \'$OISTERHOME/build/language_models/scripts/build-large-lm.pl --text=$text_file --lm=$corpus_lm_file --smoothing=$smoothing_lm --order=$order --ext-path=$external_path --keep-files 2> $current_dir/err.job.$job_counter.log\; sleep 10\; touch $current_dir/finished.$job_counter\' >& /dev/null \&";
    push(@jobs_tbd,$job_call);
    $job_counter++;
}

if(defined($ppl_file) && -e "$current_dir/ppl") {
    print STDERR "Error: $current_dir/ppl exists. Please remove.\n";
    exit(-1);
}


my @lms;
if(defined($lm_list) && $lm_list ne '') {
    my @lm_args=split(/\,/,$lm_list);
    for(my $i=0; $i<@lm_args; $i++) {
	my $lm=File::Spec->rel2abs($lm_args[$i]);
	if(&check_lm_order($order,$lm)) {
	    $lms[$job_counter+$i]=$lm;
	} else {
	    print STDERR "lm file \"$lm\" is not of order $order\n";
	    exit(-1);
	}
    }
}
    
for(my $i=0; $i<100; $i++) {
    if(-e "$current_dir/build\_$i") {
	my $rm_call="rm -rf $current_dir/build_$i";
	print STDERR "$rm_call\n";
	system($rm_call);
    }
    if(-e "$current_dir/err.job.$i.log") {
	my $rm_call="rm -rf $current_dir/err.job.$i.log";
	print STDERR "$rm_call\n";
	system($rm_call);
    }
    if(-e "$current_dir/finished.$i") {
	my $rm_call="rm -rf $current_dir/finished.$i";
	print STDERR "$rm_call\n";
	system($rm_call);
    }
}

my $num_active_jobs=0;
my %finished_jobs;
my %built_models;
while(@jobs_tbd>0 || $num_active_jobs>0) {
    if($num_active_jobs<$num_parallel && @jobs_tbd>0) {
	my $job_call=shift(@jobs_tbd);
	print STDERR "\nStarting job: $job_call\n";
	system($job_call);
	$num_active_jobs++;
    }

    opendir(D,"$current_dir");
    while(defined(my $file=readdir(D))) {
	if($file=~/^finished\.([0-9]+)$/) {
	    my $job_id=$1;
	    if(!exists($finished_jobs{$file})) {
		$finished_jobs{$file}=1;
		print STDERR "finished file: $file\n";
		$num_active_jobs--;
		if($clean_up) {
		    while(defined(my $lm_file=readdir(D))) {
			if($lm_file=~/\.$job_id\.lm$/ && !(-z "$current_dir/$lm_file")) {
			    $lms[$job_id]="$current_dir/$lm_file";
			    $built_models{"$current_dir/$lm_file"}=1;
			    my @rm_calls;
			    push(@rm_calls,"rm -rf $current_dir/build_$job_id");
			    push(@rm_calls,"rm -rf $current_dir/err.job.$job_id.log");
			    push(@rm_calls,"rm -rf $current_dir/finished.$job_id");
			    for(my $i=0; $i<@rm_calls; $i++) {
				print STDERR "$rm_calls[$i]\n";
				system($rm_calls[$i]);
			    }
			    last;
			}
		    }
		}
	    }
	}
    }
    closedir(D);
    sleep(2);
}

if(!defined($lm_file)) {
    print STDERR "No interpolation is carried out. --lm is not specified.\n";
    exit(-1);
}


my $ppl_file_name;
if(defined($ppl_file)) {
    system("mkdir $current_dir/ppl");
    ($ppl_file_name)=$ppl_file=~/^.*?([^\/]+)$/;
    my $preprocessing_pipeline='';
    if($preprocessing_flags ne '') {
	my %flags;
	my(@parts)=split(/\,/,$preprocessing_flags);
	for(my $i=0; $i<@parts; $i++) {
	    $flags{$parts[$i]}=1;
	}
	undef @parts;
	if(exists($flags{'lc'})) {
	    push(@parts,"$OISTERHOME/build/language_models/scripts/lowercase.pl");
	}
	if(exists($flags{'numsub'})) {
	    push(@parts,"$OISTERHOME/build/language_models/scripts/substitute_numbers.pl");
	}
	if(exists($flags{'dedupl'})) {
	    push(@parts,"sort -u -T $working_dir");
	}
	if(exists($flags{'sent_tags'})) {
	    push(@parts,"$OISTERHOME/build/language_models/scripts/add_sent_tags.pl");
	}
	$preprocessing_pipeline=join(" \| ",@parts);
	$preprocessing_pipeline="\| $preprocessing_pipeline";
    }
    my $ppl_cat_call="cat $ppl_file $preprocessing_pipeline > $current_dir/ppl/$ppl_file_name";
    print STDERR "$ppl_cat_call\n";
    system($ppl_cat_call);
    $ppl_file="$current_dir/ppl/$ppl_file_name";


}


my @lambdas;
my $num_lms=@lms;
my $lambda_init=&round_off((1/$num_lms),4);
for(my $i=0; $i<@lms; $i++) {
    $lambdas[$i]=$lambda_init;
}

if(defined($ppl_file)) {
    my @ppl_files;
    for(my $i=0; $i<@lms; $i++) {
	my $ppl_call="ngram -order $order -debug 2 -lm $lms[$i] -ppl $ppl_file 1> $current_dir/ppl/$ppl_file_name.$i.ppl";
	print STDERR "$ppl_call\n";
	system($ppl_call);
	$ppl_files[$i]="$current_dir/ppl/$ppl_file_name.$i.ppl";
    }

    my $lambda_string=join(' ',@lambdas);
    my $ppl_string=join(' ',@ppl_files);
    my $ppl_mix_call="compute-best-mix lambda=\"$lambda_string\" $ppl_string >& $current_dir/ppl/interpolation.log";
    print STDERR "$ppl_mix_call\n";
    system($ppl_mix_call);

    my $best_lambda_string;
    open(F,"<$current_dir/ppl/interpolation.log")||die("can't open file $current_dir/ppl/interpolation.log: $!\n");
    while(defined(my $line=<F>)) {
	if($line=~/\, best lambda \(([^\)]+)\)[\s\t]*\n/) {
	    $best_lambda_string=$1;
	    last;
	}
    }
    close(F);

    if(!defined($best_lambda_string)) {
	print STDERR "Error in estimating min perplexities.\n";
	exit(-1);
    }

    my @best_lambdas=split(/ +/,$best_lambda_string);
    if(!@best_lambdas==@lambdas) {
	print STDERR "Error in estimating min perplexities.\n";
	exit(-1);
    }

    for(my $i=0; $i<@best_lambdas; $i++) {
	$lambdas[$i]=$best_lambdas[$i];
    }
}

my @mix_lms;
my @mix_lambdas;
my $lambda_sum=0;
for(my $i=0; $i<@lms; $i++) {
    $lambda_sum+=$lambdas[$i];
    my $mix_flag="\-mix\-lm$i";
    my $mix_lambda_flag="\-mix\-lambda$i";
    if($i==0) {
	$mix_flag="\-lm";
	$mix_lambda_flag="\-lambda";
    } elsif($i==1) {
	$mix_flag="\-mix\-lm";
    }

    if($i!=1) {
	push(@mix_lambdas,"$mix_lambda_flag $lambdas[$i]");
    }
    $mix_lms[$i]="$mix_flag $lms[$i]";
}
print STDERR "lambda-sum=$lambda_sum\n";
my $mix_lm_string=join(' ',@mix_lms);
my $mix_lambda_string=join(' ',@mix_lambdas);
my $write_lm_flag='-write-lm';
if($binary_lm) {
    $write_lm_flag='-write-bin-lm';
}

my $lm_interpolation_call="ngram -order $order $mix_lm_string $mix_lambda_string $write_lm_flag $lm_file";
print STDERR "$lm_interpolation_call\n";
system($lm_interpolation_call);

$lm_file=File::Spec->rel2abs($lm_file);
if(-e "$lm_file" && !(-z "$lm_file")) {
    print STDERR "All completed. Resulting interpolated LM=$lm_file\n";
    if($delete_builds) {
	foreach my $file (keys %built_models) {
	    my $rm_call="rm -f $file";
	    print STDERR "$rm_call\n";
	    system($rm_call);
	}
	my $rm_call="rm -rf $current_dir/ppl"; 
	print STDERR "$rm_call\n";
	system($rm_call);	
    }
} else {
    print STDERR "Error: Somethings seems to have gone wrong!\n";
    exit(-1);
}


sub check_lm_order {
    my($order,$lm)=@_;
    my $c=0;
    my $lm_max_order=0;
    open(F,"<$lm")||die("can't open file $lm: $!\n");
    while(defined(my $line=<F>)) {
	$c++;
	if($c>$order+5) {
	    last;
	} else {
	    if($line=~/^ngram ([0-9]+)\=[0-9]+\n/) {
		my $lm_order=$1;
		if($lm_order>$lm_max_order) {
		    $lm_max_order=$lm_order;
		}
	    } elsif($line=~/^maxorder[\s\t]+([0-9]+)[\s\t]*\n/) {
		$lm_max_order=$1;
		last;
	    }
	}
    }
    close(F);

    if($order==$lm_max_order) {
	return 1;
    } else {
	return 0;
    }
}


sub round_off {
    my($num,$num_digits)=@_;
    $num_digits||=6;
    my $min_prob=10**-15;
    my $sprintf_string=$num_digits . 'f';
    my $rounded_num=sprintf("%.$sprintf_string",$num);
    $rounded_num=~s/0+$//;
    $rounded_num=~s/\.$//;
    $rounded_num=$min_prob if($rounded_num==0);

    return $rounded_num;
}

sub print_help {
   print "\nOptions:
  --input-corpora=str : comma-separated list of input files
                  format: --input-corpora=<tuple1>,<tuple2>,...
                  where tupleN = <min-counts>:<smoothing>:text_file
                  text_file is a plain text input file (one sentence 
                  per line)
  --input-lms=str : comma-separated list of already built LMs
  --lm=str : name of resulting LM file
  --ppl=str : name of text file used for perplexity minimization
  --num-parallel=int : number of parallel builds (default=1)
         This dependes on the size of the corpora. It's recommended
         to keep this value <5.
  --external-path=str : path to 3rd party software directory
         generated by $OISTERHOME/install/scripts/oister-link-external-components.pl
  --batch-size=int : number of sentences per batch (default=1000000)
  --pre-processing=str : comma-separated values={lc,numsub,dedupl,sent_tags}
                 default=lc,numsub,dedupl,sent_tags
  --working-dir=str : new directory to store temporary file
                  (default=working_dir)
  --order=int : n-gram order of LM (default=5)
  --delete-builds : delete individual LMs after interpolation.
  --binary-lm : write resulting LM file in binary format
  --min-counts=str : min frequence of events for respective order
              (default=1-1-1-2-2). This is the global min-counts setting.
              This can be overridden for individual corpora within
              --input-corpora .
  --smoothing=str : smoothing scheme (default=kndiscount)
              This is the global smoothing setting.
              This can be overridden for individual corpora within
              --input-corpora .
  --no-interpolation : do not interpolate with lower-order models
  --keep-files : keep temporary files for debugging purposes
  --help : print this message.\n\n";
}
