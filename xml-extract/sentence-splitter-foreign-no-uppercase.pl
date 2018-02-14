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

for($i=0; $i<@paras; $i++) {
    $paras[$i]=~s/([^ 0-9])([\.\!\?]\"?) (\"?[^ ])/$1$2\n$3/g;
    $paras[$i]=~s/ St\.\n/ St. /g;
}

if($print_p_tags) {
    $text=join(" <\/s>\n<p>\n<s> ",@paras);
} else {
    $text=join("\n",@paras);
}
print $text, "\n";
