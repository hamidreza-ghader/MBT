#!/usr/bin/perl -w

use strict;
use warnings;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while(defined(my $line=<STDIN>)) {
    $line=~tr/0-9/6/;
    print $line;
}
