#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long "GetOptions";
use File::Spec::Functions;
use IO::File;
use Encode;
use FindBin '$Bin';

my $pid=$$;

use PerlIO::gzip;

my $input_file;
my $output_file;
my $use_stdio=0;
my $num_parallel=1;
my $num_batches=0;
my $language;
my $print_languages=0;
my $clean_up=1;
my $keep_files;
my $only_preprocess;
my $use_tmpfs=0;
my $tmpfs_loc='/dev/shm/';
my $external_path;

my $_HELP;
$_HELP = 1
    unless &GetOptions(
        "input-file|i=s" => \$input_file,
        "output-file|o=s" => \$output_file,
        "language|lang|l=s" => \$language,
        "external-path|ext_path=s" => \$external_path,
        "print-languages" => \$print_languages,
        "num-parallel|p=i" => \$num_parallel,
        "num-batches|num-batch|b=i" => \$num_batches,
        "keep-files" => \$keep_files,
        "only-preprocess" => \$only_preprocess,
        "tmpfs|tempfs" => \$use_tmpfs,
        "tmpfs-loc|tempfs-loc" => \$tmpfs_loc,
        "help|h" => \$_HELP,
    );



if ($_HELP) {
    print "Options:
  --input-file=str : name of input-file (if not specified: stdin)
  --output-file=str : name of tokenized output file (if not specified: stdout)
  --language=str : language of the input file
  --external-path=str : path to externel segmenters
  --num-parallel=int : degree of parallelization (default=1)
  --num-batches=int : split data in n batches (default=num-parallel)
  --keep-files : do not remove temporary files
  --only-preprocess : do not tokenize but only clean/normalize special characters. To be used as preprocessing for other tokenizers (e.g. Stanford).
  --tmpfs : use tmpfs
  --tmpfs-loc=str : tmpfs location (default=/dev/shm/)
  --help : print this message.\n\n";
    exit(-1);
}

my $current_dir=File::Spec->rel2abs('.');
if(defined($input_file)) {
    $input_file=File::Spec->rel2abs($input_file);
}
if(defined($output_file)) {
    $output_file=File::Spec->rel2abs($output_file);
}

if($num_batches==0) {
    $num_batches=$num_parallel;
}

$num_parallel=&min($num_parallel,$num_batches);


#$external_path=File::Spec->rel2abs($external_path);
my $tmp_dir="$current_dir/tmp.$pid";
if($use_tmpfs) {
    $tmp_dir="/$tmpfs_loc/tmp.$pid";
}

if(defined($keep_files)) {
    $clean_up=0;
}

if($only_preprocess) {
    print STDERR "Applying preprocessing only...\n";
    if(!defined($input_file)) {
        while(defined(my $line=<STDIN>)) {
            chomp($line);
            $line=&replace_special_characters($line);
            if($line=~/^[\s\t]*$/) {
                $line='NIL';
            }
            print STDOUT $line, "\n";
        }
    }
    elsif(defined($input_file)) {
        if($input_file=~/\.gz$/o) {
            open I, "<:gzip", $input_file, or die("can't open $input_file: $!\n");
        } else {
            open(I,"<$input_file") || die("can't open $input_file: $!\n");
        }
        while(defined(my $line=<I>)) {
            chomp($line);
            $line=&replace_special_characters($line);
            if($line=~/^[\s\t]*$/) {
                $line='NIL';
            }
            print STDOUT $line, "\n";
        }
    }
    print STDERR "done.\n";
    exit 1;
}

my $plain_file="$tmp_dir/text.in";

my $size_total=0;
my $num_input_lines=0;
if(!defined($input_file)) {
    my $first_line=1;
    while(defined(my $line=<STDIN>)) {
	if($first_line) {
	    if(!(-e "$tmp_dir")) {
		system("mkdir $tmp_dir");
	    } 
	    open(F,">$plain_file");
	    $first_line=0;
	}

	chomp($line);
	$line=&replace_special_characters($line);
	if($line=~/^[\s\t]*$/) {
	    $line='NIL';
	}
	$num_input_lines++;
	my(@chars)=split(//,$line);
	$size_total+=@chars;
	print F $line, "\n";
    }
    close(F);
} elsif(defined($input_file)) {
    if(!(-e "$tmp_dir")) {
	system("mkdir $tmp_dir");
    } 
    if($input_file=~/\.gz$/o) {
        open I, "<:gzip", $input_file, or die("can't open $input_file: $!\n");
    } else {
        open(I,"<$input_file") || die("can't open $input_file: $!\n");
    }
    open(F,">$plain_file");
    while(defined(my $line=<I>)) {
	chomp($line);
	$line=&replace_special_characters($line);
	if($line=~/^[\s\t]*$/) {
	    $line='NIL';
	}
	$num_input_lines++;
	my(@chars)=split(//,$line);
	$size_total+=@chars;
	print F $line, "\n";
    }
    close(F);
    close(I);
}

if(defined($language) && ($language=~/^(chinese|zh|ch|chi)\:/ || $language=~/^(chinese|zh|ch|chi)$/)) {
    my $trad2simp_call="cat $plain_file | $Bin/./chinese_traditional2simplified.pl > $plain_file.simp";
    print STDERR "$trad2simp_call\n";
    system($trad2simp_call);
    system("mv $plain_file.simp $plain_file");
}

my @batch_input_file;
my @batch_input_lines;
$num_batches=&split_file($plain_file,$size_total,$num_input_lines,$num_batches,\@batch_input_file,\@batch_input_lines);

my %job_calls;
my @batch_output_file;
my @jobs_tbd;
for(my $i=0; $i<@batch_input_file; $i++) {
    $batch_output_file[$i]="$batch_input_file[$i].tok";
    my $used_tokenizer;
    my $chdir=0;
    my $tokenize_call=&generate_tokenize_call($batch_input_file[$i],$batch_output_file[$i],$language,\$used_tokenizer,\$chdir);
    if($i==0 && defined($used_tokenizer)) {
#	print STDERR "$tokenize_call\n";
	print STDERR "Using tokenizer: $used_tokenizer\n";
    }
    my $chdir_call='';
    $chdir_call="cd $tmp_dir\;" if($chdir);
    my $finished_file="$tmp_dir/finished.$i";
    my $job_call="nohup sh -c \'$chdir_call$tokenize_call 2> $tmp_dir/err.$i.log\; sleep 1\; touch $finished_file\; cd $current_dir\' >\& /dev/null \&";
    $job_calls{$job_call}=$finished_file;
    push(@jobs_tbd,$job_call);
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

    foreach my $job_call (keys %job_calls) {
	my $file=$job_calls{$job_call};
	if(-e "$file" && !exists($finished_jobs{$file})) {
	    $finished_jobs{$file}=1;
	    print STDERR "finished file: $file\n";
	    $num_active_jobs--;

	    my $job_id;
	    if($file=~/finished\.([0-9]+)$/) {
		$job_id=$1;
	    }

	    if($clean_up) {
		my @rm_calls;
		push(@rm_calls,"rm -rf $file");
		push(@rm_calls,"rm -rf $tmp_dir/err.job.$job_id.log");

		for(my $i=0; $i<@rm_calls; $i++) {
		    print STDERR "$rm_calls[$i]\n";
		    system($rm_calls[$i]);
		}		
	    }	 
#	    sleep(1);
	}
    }
    sleep(1);
}



#my $num_active_jobs=0;
#foreach my $job (keys %job_calls) {
##    print STDERR "$job\n";
#    system($job);
#    $num_active_jobs++;
#}
#
#my %finished_jobs;
#while($num_active_jobs>0) {
#    foreach my $job (keys %job_calls) {
#	if(-e "$job_calls{$job}" && !exists($finished_jobs{$job_calls{$job}})) {
#	    $finished_jobs{$job_calls{$job}}=1;
#	    $num_active_jobs--;
#	}
#    }
#    sleep(1);
#}

my $errors=0;
for(my $i=0; $i<@batch_input_file; $i++) {
    my $num_output_lines=&number_lines($batch_output_file[$i]);
    if($num_output_lines!=$batch_input_lines[$i]) {
	print STDERR "Error in file $batch_output_file[$i]\n";
	$errors++;
    }
}

if($errors>0) {
    print STDERR "Tokenization failed.\n";
    exit(-1);
}

if(!defined($output_file)) {
    for(my $i=0; $i<@batch_output_file; $i++) {
	my $file=$batch_output_file[$i];
	open(F,"<$file");
	while(defined(my $line=<F>)) {
	    print $line;
	}
	close(F);
    }
} elsif(defined($output_file)) {
    if($output_file=~/\.gz$/o) {
        open O, ">:gzip", $output_file, or die("can't open $output_file: $!\n");
    } else {
        open(O,">$output_file") || die("can't open $output_file: $!\n");
    }
    for(my $i=0; $i<@batch_output_file; $i++) {
	my $file=$batch_output_file[$i];
	open(F,"<$file");
	while(defined(my $line=<F>)) {
	    print O $line;
	}
	close(F);
    }
    close(O);
}

if($clean_up) {
    my $rm_call="rm -rf $tmp_dir";
#    print STDERR "$rm_call\n";
    system($rm_call);
}




sub number_lines {
    my($file)=@_;
    if(!(-e "$file")) {
	return 0;
    }
    my $num_lines=0;
    open(F,"<$file");
    while(defined(my $line=<F>)) {
	$num_lines++;
    }
    close(F);
    return $num_lines;
}

sub split_file {
    my($plain_file,$total_size,$total_lines,$num_batches,$in_files,$batch_input_lines)=@_;

    my $avg_batch_size=$total_size/$num_batches;
    my $current_size=0;
    my $current_lines=0;
    my $batch_id=0;
    my $num_lines=0;
    open(F,"<$plain_file");
    open(B,">$plain_file.$batch_id");
    while(defined(my $line=<F>)) {
        chomp($line);
	$num_lines++;
	my(@chars)=split(//,$line);
	$current_size+=@chars;
	$current_lines++;
	print B $line, "\n";

	if($current_size>=$avg_batch_size || $num_lines==$total_lines) {
	    close(B);
	    push(@$in_files,"$plain_file.$batch_id");
	    push(@$batch_input_lines,$current_lines);
	    $current_size=0;
	    $current_lines=0;
	    if($num_lines<$total_lines) {
		$batch_id++;
		open(B,">$plain_file.$batch_id");
	    }
	}
    }
    close(F);

    return $batch_id+1;
}

    
sub generate_tokenize_call {
    my($input_file,$output_file,$language,$tokenizer,$chdir)=@_;

    #my($language,$scheme)=split(/\:/,$language_scheme);
    if(defined($language))
    {
      $language=&normalize_language($language);
    }
    #my $scheme||='default';

    $$chdir=0;

    # default
    my $call="cat $input_file \| $Bin/./tokenizeANY.pl \- \- 1> $output_file";
    $$tokenizer='tokenizeANY.pl';

    # arabic
    if(defined($language) && $language=~/^(arabic)$/) {
        if(!defined($external_path))
        {
          print STDERR "To tokenzie arabic --external-path=str must be set to stanford segmenter\n";
          exit(-1);
        }
        $call = "java -cp $external_path/seg.jar -mx8g edu.stanford.nlp.international.arabic.process.ArabicSegmenter -loadClassifier $external_path/data/arabic-segmenter-atbtrain.ser.gz -textFile $input_file 1> $output_file";
	#$call="cat $input_file \| $SMTAMS/scripts/ortho_mada.sh -t $mada_scheme | $OISTERHOME/preprocessing/scripts/lib/mada2mt.pl 1> $output_file";
	#$$tokenizer="mada -t $mada_scheme";
	$$tokenizer='stanford-segmenter-arabic atb';
	#$$chdir=1;

    # chinese	
    } elsif(defined($language) && $language=~/^(chinese)$/) {
            if(!defined($external_path))
            {
               print STDERR "To tokenzie chinese --external-path=str must be set to stanford segmenter\n";
               exit(-1);
             }
	    #$call="$external_path/external_binaries/stanford_segmenter/segment.sh ctb $input_file UTF-8 0 1> $output_file";
	    $call="$external_path/segment.sh ctb $input_file UTF-8 0 1> $output_file";
            $$tokenizer='stanford-segmenter-chinese ctb';

    # english
    } elsif(defined($language) && $language=~/^(english)$/) {
	#$call="cat $input_file \| $OISTERHOME/preprocessing/scripts/lib/tokenizeE.pl \- \- 1> $output_file";
	$call="cat $input_file \| $Bin/./tokenizeE.pl \- \- 1> $output_file";
	$$tokenizer='tokenizeE.pl';

    # french
    } elsif(defined($language) && $language=~/^(french)$/ ) {

           if(!defined($external_path))
            {
               print STDERR "To tokenzie french --external-path=str must be set to moses home\n";
               exit(-1);
             }

#	$call="cat $input_file \| $external_path/moses/scripts/tokenizer/tokenizer.perl -l fr -threads 1 | $external_path/moses/scripts/tokenizer/deescape-special-chars.perl 1> $output_file";
        $call="cat $input_file \| $external_path/scripts/tokenizer/tokenizer.perl -l fr -threads 1 | $external_path/scripts/tokenizer/deescape-special-chars.perl 1> $output_file";
	$$tokenizer='moses-tokenizer.perl';

    # italian
    } elsif(defined($language) && $language=~/^(italian)$/) {
           if(!defined($external_path))
            {
               print STDERR "To tokenzie french --external-path=str must be set to moses home\n";
               exit(-1);
             }

	$call="cat $input_file \| $external_path/moses/scripts/tokenizer/tokenizer.perl -l it -threads 1 | $external_path/moses/scripts/tokenizer/deescape-special-chars.perl 1> $output_file";
	$$tokenizer='moses-tokenizer.perl';
    }

    return $call;
}
	
  

sub normalize_language {
    my($l)=@_;
    $l=~tr/A-Z/a-z/;
    if($l=~/^(ar|ara|arabic)$/) {
	$l='arabic';
    } elsif($l=~/^(chinese|zh|ch)/) {
	$l='chinese';
    }  elsif($l=~/^(en|eng|english)/) {
	$l='english';
    }  elsif($l=~/^(fr|fre|french|francais)/) {
	$l='french';
    }  elsif($l=~/^(it|ita|italian|italiano)/) {
    $l='italian';
    } else {
	$l='unknown';
    }
    return $l
}



sub replace_special_characters {
    my($string)=@_;
    $string||='';

    $string=decode('utf8',$string);

    $string=~s/\p{Control}/ /g;
    $string=~s/\p{Other}/ /g;
    $string=~s/\p{Format}/ /g;
    $string=~s/\p{Private_Use}/ /g;
    $string=~s/\p{Unassigned}/ /g;


    # replace different white space characters with normal white space
    $string=~s/\x{00A0}/ /g;
    $string=~s/\x{1680}/ /g;
    $string=~s/\x{180E}/ /g;
    $string=~s/\x{2000}/ /g;
    $string=~s/\x{2001}/ /g;
    $string=~s/\x{2002}/ /g;
    $string=~s/\x{2003}/ /g;
    $string=~s/\x{2004}/ /g;
    $string=~s/\x{2005}/ /g;
    $string=~s/\x{2006}/ /g;
    $string=~s/\x{2007}/ /g;
    $string=~s/\x{2008}/ /g;
    $string=~s/\x{2009}/ /g;
    $string=~s/\x{200A}/ /g;
    $string=~s/\x{202F}/ /g;
    $string=~s/\x{205F}/ /g;
    $string=~s/\x{3000}/ /g;

    $string=~s/ +/ /g;
    $string=~s/^ +//;
    $string=~s/ +$//;

    return encode('utf8',$string);
}

sub min {
    return $_[0] if($_[0]<$_[1]);
    return $_[1];
}
