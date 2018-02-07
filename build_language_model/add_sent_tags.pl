#!/usr/bin/perl -w

use strict;
use warnings;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while(defined(my $line=<STDIN>)) {
    chomp($line);
    $line=~s/^[\s\t]*<s>[\s\t]*//;
    $line=~s/[\s\t]*<\/s>[\s\t]*$//;
    $line="<s> $line <\/s>\n";
    print $line;
}
