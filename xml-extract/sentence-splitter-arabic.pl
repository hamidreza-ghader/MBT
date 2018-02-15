#!/usr/bin/perl -w

#binmode(STDIN, ":utf8");
#binmode(STDOUT, ":utf8");

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

    for(my $i=0; $i<@paras; $i++) {
	my @lines=split(/\n/,$paras[$i]);
	for(my $j=0; $j<@lines; $j++) {
	    $line=$lines[$j] . "\n";

	    if($line=~/^<p>\n/ || $line=~/^(<p>)?[\s\t]*\n/) {
		next;
	    }
	
	    if($line=~/^00000918273645375993000/) {
		print "$line";
		next;
	    }
	    
	    while($line=~s/([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)/$1NOSENTDOC$2/) {
	    }
	    $line=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:\?])/\\$1/g;
	    $line_copy=$line;
	    
#    while($line_copy=~s/ ([^ ]+) \x2e ([^ ]+) //) {
	    while($line_copy=~s/ ([^ ]+[\s\t]*)\\\x2e ([^ ]+) //) {
		$left=$1;
		$right=$2;
#	print STDERR "left=$left\nright=$right\n";
		if($left=~/^[0-9]+$/ && $right=~/^[0-9]+$/) {
		} else {
#	    $line=~s/ $left \x2e $right / $left \x2e\n$right /;
#	    $left=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:])/\\$1/g;
#	    $right=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:])/\\$1/g;
		    $line=~s/ $left\\\x2e $right / $left \x2e\n$right /;
		}
	    }
	    $line=~s/\s*\\([\(\)\[\]\{\}\$\#\.\`\|\;\+\/\*\!\@\:\?])\s*/ $1 /g;
	    $line=~s/http\s*:\s*\/\s*\/\s*/http:\/\//g;
	    $line=~s/ \@ /\@/g;
	    
	    $line=~s/([A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])([^A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])/$1 $2/g;
	    $line=~s/([^A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])([A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])/$1 $2/g;
	    
	    $line=~s/(http:\/\/[^ ]+)\s+\//$1\//g;
	    while($line=~s/(http:\/\/[^ ]+\/)\s+([^ ]+)\s*\//$1$2\/ /) {
	    }
	    $line=~s/(http:\/\/[^ ]+\/)\s+([A-Za-z0-9\?\=\&\.\/]+)/$1$2/g;
	    
#   $line=~s/(\P{Latin})(\p{Latin})/$1 $2/g;
#    $line=~s/(\p{Latin})(\P{Latin})/$1 $2/g;
	    
	    $line=~s/^\s*//;
	    $line=~s/NOSENTDOC/./g;
	    $line=~s/\s*\n\s*/\n/;
	    $line=~s/ +/ /g;
	    if($line!~/\n$/) {
		$line.="\n";
	    }
	    
	    print $line;
	    if($i<@paras-1) {
		print "<p>\n";
	    }
	}
    }

} else {
    while(defined($line=<STDIN>)) {
	if($line=~/^<p>\n/ || $line=~/^(<p>)?[\s\t]*\n/) {
	    next;
	}
	
	if($line=~/^00000918273645375993000/) {
	    print "$line";
	    next;
	}
	
	while($line=~s/([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)/$1NOSENTDOC$2/) {
	}
	$line=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:\?])/\\$1/g;
	$line_copy=$line;
	
#    while($line_copy=~s/ ([^ ]+) \x2e ([^ ]+) //) {
	while($line_copy=~s/ ([^ ]+[\s\t]*)\\\x2e ([^ ]+) //) {
	    $left=$1;
	    $right=$2;
#	print STDERR "left=$left\nright=$right\n";
	    if($left=~/^[0-9]+$/ && $right=~/^[0-9]+$/) {
	    } else {
#	    $line=~s/ $left \x2e $right / $left \x2e\n$right /;
#	    $left=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:])/\\$1/g;
#	    $right=~s/([\(\)\[\]\{\}\$\#\.\`\|\;\/\\\+\*\!\@\:])/\\$1/g;
		$line=~s/ $left\\\x2e $right / $left\x2e\n$right /;
	    }
	}
	$line=~s/\\([\(\)\[\]\{\}\$\#\.\`\|\;\+\/\*\!\@\:\?])/$1/g;
	$line=~s/http\s*:\s*\/\s*\/\s*/http:\/\//g;
	$line=~s/ \@ /\@/g;
	
	$line=~s/([A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])([^A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])/$1$2/g;
	$line=~s/([^A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])([A-Za-z0-9\~\@\#\$\%\^\&\*\(\)\-\+\=\_\{\[\}\]\:\;\"\'\<\.\,\.\?\/\|\\\`])/$1$2/g;
	
	$line=~s/(http:\/\/[^ ]+)\s+\//$1\//g;
	while($line=~s/(http:\/\/[^ ]+\/)\s+([^ ]+)\s*\//$1$2\//) {
	}
	$line=~s/(http:\/\/[^ ]+\/)\s+([A-Za-z0-9\?\=\&\.\/]+)/$1$2/g;
	
#   $line=~s/(\P{Latin})(\p{Latin})/$1 $2/g;
#    $line=~s/(\p{Latin})(\P{Latin})/$1 $2/g;
	
	$line=~s/^\s*//;
	$line=~s/NOSENTDOC/./g;
	$line=~s/\s*\n\s*/\n/;
	$line=~s/ +/ /g;
	if($line!~/\n$/) {
	    $line.="\n";
	}
	
	print $line;
    }
}
