#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long "GetOptions";
use File::Spec::Functions;

my $arg_string=join(' ',@ARGV);
my $command=$0;

print STDERR "\ncall: $command $arg_string\n\n";
my $pid=$$;

my $_HELP;
my $lm_file;
my $bin_lm_file;
my $order;
my $external_path;

$_HELP = 1
    unless &GetOptions(
  "lm=s" => \$lm_file,
  "bin-lm|binary-lm|blm=s" => \$bin_lm_file,
  "external-path|ext-path=s" => \$external_path,
  "order=i" => \$order,
  "help|h" => \$_HELP
    );

if(!defined($lm_file) || !defined($bin_lm_file) || !defined($order)) {
    $_HELP=1;
}

if(!defined($external_path)) {
    print STDERR "  --external-path=str must be set\n";
    $_HELP=1;
}

if($_HELP) {
    print "\nOptions:
  --lm=str : name of input LM file
  --bin-lm=str : name of resulting binary LM file
  --order=int : n-gram order of LM
  --external-path=str : path to 3rd party software directory generated by
         \$OISTERHOME/install/scripts/oister-link-external-components.pl
  --help : print this message.\n\n";
    exit(-1);
}

$lm_file=File::Spec->rel2abs($lm_file);
$bin_lm_file=File::Spec->rel2abs($bin_lm_file);

my $srilm_bin="$external_path/external_binaries/srilm/";
my $srilm_bin_machinetype="$external_path/external_binaries/srilm/bin_machine_type";

my $PATH=$ENV{'PATH'};
$ENV{'PATH'}="$PATH:$srilm_bin:$srilm_bin_machinetype";

if($lm_file eq $bin_lm_file) {
    print STDERR "Error: values for --text and --lm must be different.\n";
    exit(-1);
}

my $binarize_call="ngram -order $order -lm $lm_file -write-bin-lm $bin_lm_file";
print STDERR "$binarize_call\n";
system($binarize_call);
