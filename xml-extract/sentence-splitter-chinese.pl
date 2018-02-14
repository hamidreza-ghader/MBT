#!/usr/bin/perl -w

use strict;
use warnings;

while(defined(my $line=<STDIN>)) {
    chomp($line);
    my $orig_line=$line;

    # o "\s
    $line=~s/\xe3\x80\x82\s*(\x22)\s+([^ ])/\_CHINESEFULLSTOP\_$1\n$2/g;
    # o "
    $line=~s/\xe3\x80\x82\s*(\x22)\s*([^ ])/\_CHINESEFULLSTOP\_$1\n$2/g;
    # o "$
    $line=~s/\xe3\x80\x82\s*(\x22)\s*$/\_CHINESEFULLSTOP\_$1/g;
    # o >\s
    $line=~s/\xe3\x80\x82\s*(\xe3\x80\x8d)\s+([^ ])/\_CHINESEFULLSTOP\_$1\n$2/g;
    # o >
    $line=~s/\xe3\x80\x82\s*(\xe3\x80\x8d)\s*([^ ])/\_CHINESEFULLSTOP\_$1\n$2/g;
    # o >$
    $line=~s/\xe3\x80\x82\s*(\xe3\x80\x8d)\s*$/\_CHINESEFULLSTOP\_$1/g;
    # ? "\s
    $line=~s/\xef\xbc\x9f\s*(\x22)\s+([^ ])/\_CHINESEQUESTIONMARK\_$1\n$2/g;
    # ? "
    $line=~s/\xef\xbc\x9f\s*(\x22)\s*([^ ])/\_CHINESEQUESTIONMARK\_$1\n$2/g;
    # ? "$
    $line=~s/\xef\xbc\x9f\s*(\x22)\s*$/\_CHINESEQUESTIONMARK\_$1/g;
    # ? >\s
    $line=~s/\xef\xbc\x9f\s*(\xe3\x80\x8d)\s+([^ ])/\_CHINESEQUESTIONMARK\_$1\n$2/g;
    # ? >
    $line=~s/\xef\xbc\x9f\s*(\xe3\x80\x8d)\s*([^ ])/\_CHINESEQUESTIONMARK\_$1\n$2/g;
    # ? >$
    $line=~s/\xef\xbc\x9f\s*(\xe3\x80\x8d)\s*$/\_CHINESEQUESTIONMARK\_$1/g;

    # o
    $line=~s/\xe3\x80\x82\s*([^\n])/\_CHINESEFULLSTOP\_\n$1/g;
    # ?
    $line=~s/\xef\xbc\x9f\s*([^\n])/\_CHINESEQUESTIONMARK\_\n$1/g;

    $line=~s/\_CHINESEFULLSTOP\_/\xe3\x80\x82/g;
    $line=~s/\_CHINESEQUESTIONMARK\_/\xef\xbc\x9f/g;

    $line=~s/\s*\n\s*/\n/g;
    $line=~s/\n+/\n/g;
    $line=~s/\s*\n+$//;

    print $line, "\n";

    # for debugging:
    if(0 && $line ne $orig_line) {
	print STDERR "orig : $orig_line\n";
	print STDERR "split: $line\n";
   }

}
