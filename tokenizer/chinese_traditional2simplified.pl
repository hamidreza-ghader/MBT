#!/usr/bin/perl -w

use strict;
use warnings;
use Encode;
use FindBin '$Bin';

BEGIN {
    if(!defined($ENV{'OISTERHOME'})
       || $ENV{'OISTERHOME'} eq '') {
        print STDERR "environment variable OISTERHOME must be set:\n";
        print STDERR "export OISTERHOME=/path/to/oister/distribution\n";
        exit(-1);
    }
}

my $OISTERHOME=$ENV{'OISTERHOME'};

my $chinese_simplification_table="$Bin/./simplify-table.sayjack.txt";
my %chinese_trad2simpl_map;
&load_chinese_simplification_tabe($chinese_simplification_table,\%chinese_trad2simpl_map);

while(defined(my $text=<STDIN>)) {
    $text=&convert_chinese_traditional2simplified($text,\%chinese_trad2simpl_map);
    print $text;
}


sub load_chinese_simplification_tabe {
    my($chinese_simplification_table,$map)=@_;
    open(F,"<$chinese_simplification_table")||die("can't open file $chinese_simplification_table: $!\n");
    while(defined(my $line=<F>)) {
	if($line=~/^(\d+)\s+(\d+)/) {
	    $$map{$1}=$2;
	}
    }
    close(F);
}

sub convert_chinese_traditional2simplified {
    my($text,$map)=@_;
    $text=decode('utf8',$text);
    my @characters=split(//,$text);
    for(my $i=0; $i<@characters; $i++) {
	my $ordinal=ord($characters[$i]);
	if(exists($$map{$ordinal})) {
#	    print STDERR "map $ordinal -> $$map{$ordinal}\n";
	    $characters[$i]=chr($$map{$ordinal});
	}
    }
    $text=join('',@characters);
    $text=encode('utf8',$text);
    return $text;
}



