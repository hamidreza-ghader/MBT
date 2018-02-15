#!/usr/bin/perl -w

my($print_p_tags)=@ARGV;

$print_p_tags||=0;
if($print_p_tags=~/\-\-?print-p-tags/) {
    $print_p_tags=1;
}


if($print_p_tags) {
    my $text='';
    while(defined($line=<STDIN>)) {
#	chomp($line);
	$line=~s/ +/ /g;
	$line=~s/<s> *(.*) *<\/s>\n$/$1/;
	$text.=$line;
    }
    chomp($text);
    @paras=split(/<p>/,$text);
} else {
    while(defined($line=<STDIN>)) {
	chomp($line);
	next if($line=~/^<p>$/);
	$line=~s/<s> *(.*) *<\/s>$/$1/;
	next if($line=~/^[\s\t]*$/);
    push(@paras,$line);
    }
}

if(0) {
    for($i=0; $i<@paras; $i++) {
	$paras[$i]=~s/([^0-9])([\.\!\?]\"?) (\"?[^ ])/$1$2 <\/s>\n<s> $3/g;
	$paras[$i]=~s/([\.\?\!]) <\/s>\n<s> ([\"\']) <\/s>\n/$1 $2 <\/s>\n/g;
	$paras[$i]=~s/([\.\?\!]) <\/s>\n<s> ([\"\s])\s*$/$1 $2/;
	$paras[$i]=~s/ St\. <\/s>\n<s> / St. /g;
    }
}

for($i=0; $i<@paras; $i++) {
    $paras[$i]=~s/([^0-9])([\.\!\?]\"?) (\"?[^ ])/$1$2\n$3/g;
    $paras[$i]=~s/([\.\?\!])\n([\"\'])\n/$1 $2\n/g;
    $paras[$i]=~s/([\.\?\!])\n([\"\s])\s*$/$1 $2/;
    $paras[$i]=~s/ St\.\n/ St. /g;
}


if(0) {
    if($print_p_tags) {
	$text=join(" <\/s>\n<p>\n<s> ",@paras);
    } else {
	$text=join(" <\/s>\n<s> ",@paras);
    }

    print "<s> ", $text, " </s>\n";
}

$text=join("\n",@paras);
print $text, "\n";

