#!/usr/bin/perl -w

use strict;
use warnings;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while(defined(my $line=<STDIN>)) {
    $line=lc($line);
    print $line;
};
