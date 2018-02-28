#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long "GetOptions";
use File::Spec::Functions;
use IO::File;
use Encode;
use FindBin '$Bin';

my $pid=$$;
my @doc_info_tags=qw( date language categories source genre);

use PerlIO::gzip;

my %lingua_sentence_splitters;

my $lang_string='english';
my $sentence_split=1;
my $write_stdout=0;
my $exclude_dates_string='';
my $include_dates_string='';
my $xml_input_string;
my $output_file;
my $output_dir;
my $no_sentence_split;
my $dir_per_lang=0;
my $convert_trad2simp=1;

my $_HELP;
$_HELP = 1
    unless &GetOptions(
        "xml-input=s" => \$xml_input_string,
        "output-file=s" => \$output_file,
        "output-dir=s" => \$output_dir,
        "exclude-dates=s" => \$exclude_dates_string,
        "constrain-dates=s" => \$include_dates_string,
        "no-sentence-splitting" => \$no_sentence_split,
        "stdout=i" => \$write_stdout,
        "help" => \$_HELP,
    );


if(!defined($xml_input_string)) {
    print STDERR "--xml-input must be set.\n";
    $_HELP=1;
}

if(defined($output_file) && defined($output_dir)) {
    print STDERR "You cannot specify both: --output-file and --output-dir. One or the other.\n";
    $_HELP=1;
}
if(!defined($output_file) && !defined($output_dir)) {
    print STDERR "You have to specify either --output-file or --output-dir.\n";
    $_HELP=1;
}


if ($_HELP) {
    print "Options:
  --xml-input=str : comma-separated list of xml files
  --output-file=str : one file containing all data
  --output-dir=str : one directory in which documents are stored as files
  --no-sentence-splitting : do not split sentences, default: 1
  --exclude-dates=yyyy-mm-dd,yyyy-mm,yyyy,...
  --constrain-dates=yyyy-mm-dd,yyyy-mm,yyyy,...
  --help : print this message.\n\n";
    exit(-1);
}

my @languages;
&initialize_languages($lang_string,\@languages);

if(defined($no_sentence_split)) {
    $sentence_split=0;
}

my %exclude_dates;
my $dates_to_be_excluded=&set_exclusion_dates(\%exclude_dates,$exclude_dates_string);

my %include_dates;
my $dates_to_be_included=&set_inclusion_dates(\%include_dates,$include_dates_string);

my $output_docinfo_file;
if(defined($output_file)) {
    $output_file=File::Spec->rel2abs($output_file);
    if($output_file=~/\.gz$/o) {
        open O, ">:gzip", $output_file, or die("can't open $output_file: $!\n");
    } else {
        open(O,">$output_file") || die("can't open $output_file: $!\n");
    }
    $output_docinfo_file=$output_file;
    $output_docinfo_file=~s/\.gz$//;
    $output_docinfo_file="$output_docinfo_file.docinfo.gz";

    if($output_docinfo_file=~/\.gz$/o) {
	open I, ">:gzip", $output_docinfo_file, or die("can't open $output_docinfo_file: $!\n");
    } else {
	open(I,">$output_docinfo_file") || die("can't open $output_docinfo_file: $!\n");
    }
}


my %output_lang_dirs;
my %doc_info_filehandles;
my %doc_info_files;
my %doc_info;

if(defined($output_dir)) {
    $output_dir=File::Spec->rel2abs($output_dir);
    if(!(-e "$output_dir/")) {
	my $mkdir_call="mkdir $output_dir";
	print STDERR "$mkdir_call\n";
	system($mkdir_call);
    }
    for(my $i=0; $i<@languages; $i++) {
	if($dir_per_lang) {
	    if($languages[$i] eq 'all') {
	    } else {
		$output_lang_dirs{$languages[$i]}="$output_dir/$languages[$i]";
		$doc_info_files{$languages[$i]}="$output_dir/$languages[$i]/docinfo.$languages[$i].txt";
		$doc_info_filehandles{$languages[$i]}=IO::File->new();
		if(!(-e "$output_dir/$languages[$i]")) {
		    my $mkdir_call="mkdir $output_dir/$languages[$i]";
		    print STDERR "$mkdir_call\n";
		    system($mkdir_call);
		} else {
		    if(-e "$doc_info_files{$languages[$i]}") {
			&read_doc_info($doc_info_filehandles{$languages[$i]},$doc_info_files{$languages[$i]},\%{ $doc_info{$languages[$i]} });
		    }		    
		}
	    }
	} else {
	    $output_lang_dirs{$languages[$i]}="$output_dir";
	    if($languages[$i] eq 'all') {		
	    } else {
		$doc_info_files{$languages[$i]}="$output_dir/docinfo.$languages[$i].txt";
		$doc_info_filehandles{$languages[$i]}=IO::File->new();
		if(-e "$doc_info_files{$languages[$i]}") {
		    &read_doc_info($doc_info_filehandles{$languages[$i]},$doc_info_files{$languages[$i]},\%{ $doc_info{$languages[$i]} });
		}		    
	    }
	}
    }
}

my @xml_files=split(/\,/,$xml_input_string);
for(my $i=0; $i<@xml_files; $i++) {
    my $xml_file=$xml_files[$i];
    if($xml_file=~/\.gz$/o) {
        open F, "<:gzip", $xml_file, or die("can't open $xml_file: $!\n");
    } else {
        open(F,"<$xml_file") || die("can't open $xml_file: $!\n");
    }
    print STDERR "Reading file \'$xml_file\' ...\n";
    while(defined(my $line=<F>)) {
	if($line=~/^<doc url=\"([^\"]+)\"/) {
	    my @buffer=( $line );
	    while(defined($line=<F>) && $line!~/^<\/doc>/) {
                #print STDERR $line;
		push(@buffer,$line);
	    }
	    push(@buffer,$line);

	    my %xml_fields;
	    my $field_error=&get_xml_fields(\@buffer,\%xml_fields);
            #print STDERR "$field_error\n";
	    if($field_error eq "1") {
		next;
	    }
	    my $url_stem=$xml_fields{'url'};
	    $url_stem=~s/\.[^\.]+\.html$//;
	    my $full_language=$xml_fields{'language'};
	    $xml_fields{'language'}=&map_language($xml_fields{'language'});

	    if(!&fullfills_language_restrictions($xml_fields{'language'})
	       || !&fullfills_date_restrictions($xml_fields{'date'})) {
		next;
	    }

	    my @fields=qw( headline body captions description);
	    my $text=&concatenate_xml_fields(\%xml_fields,\@fields,"\n<p>\n");

	    if($sentence_split) {
		$text=&sentence_split($xml_fields{'language'},$text);
	    }

	    $text=&remove_empty_lines($text);

	    if(defined($output_file)) {
                #print STDERR $text;
		print O $text;
		if(defined($output_docinfo_file)) {
		    my $text_info=$text;
		    chomp($text_info);
		    my @lines=split(/\n/,$text_info);
		    my $entry=&add_doc_info_entry(\%xml_fields,"$url_stem\.$xml_fields{'language'}\.html",\%doc_info,\@doc_info_tags,$output_file);
		    for(my $i=0; $i<@lines; $i++) {
			$lines[$i]=$entry;
		    }
		    $text_info=join("\n",@lines);
		    print I $text_info, "\n";		    
		}
	    } elsif(defined($output_dir)) {
		if(!$dir_per_lang && !defined($output_lang_dirs{$xml_fields{'language'}})) {
		    $output_lang_dirs{$xml_fields{'language'}}=$output_dir;
		    $doc_info_files{$xml_fields{'language'}}="$output_dir/docinfo.$xml_fields{'language'}.txt";
		    $doc_info_filehandles{$xml_fields{'language'}}=IO::File->new();
		    if(-e "$doc_info_files{$xml_fields{'language'}}") {
			&read_doc_info($doc_info_filehandles{$xml_fields{'language'}},$doc_info_files{$xml_fields{'language'}},\%{ $doc_info{$xml_fields{'language'}} });
		    }		    
		}

		if(!defined($output_lang_dirs{$xml_fields{'language'}})) {
		    $output_lang_dirs{$xml_fields{'language'}}="$output_dir/$xml_fields{'language'}";
		    $doc_info_files{$xml_fields{'language'}}="$output_dir/$xml_fields{'language'}/docinfo.$xml_fields{'language'}.txt";
		    $doc_info_filehandles{$xml_fields{'language'}}=IO::File->new();
		    if(!(-e "$output_dir/$xml_fields{'language'}")) {
			my $mkdir_call="mkdir $output_dir/$xml_fields{'language'}";
			print STDERR "$mkdir_call\n";
			system($mkdir_call);
		    } else {
			if(-e "$doc_info_files{$xml_fields{'language'}}") {
				&read_doc_info($doc_info_filehandles{$xml_fields{'language'}},$doc_info_files{$xml_fields{'language'}},\%{ $doc_info{$xml_fields{'language'}} });
			}		    
		    }			
		}
		my $outfile="$output_lang_dirs{$xml_fields{'language'}}/$url_stem\.$xml_fields{'language'}\.html";
		&add_doc_info_entry(\%xml_fields,"$url_stem\.$xml_fields{'language'}\.html",\%doc_info,\@doc_info_tags);
		open(G,">$outfile")||die("can't open $outfile: $!\n");
		print G $text;
		close(G);
	    }
	    
	}
    }
    close(F);
    print STDERR "done.\n";
}

foreach my $language (keys %doc_info_filehandles) {
    &write_doc_info($doc_info_filehandles{$language},$doc_info_files{$language},\%{ $doc_info{$language} });
}

if(defined($output_file)) {
    close(O);
    if(defined($output_docinfo_file)) {
	close(I);
    }
}


sub sentence_split {
    my($language,$text)=@_;

    my @paragraphs=split(/\n+<p>\n+/,$text);
    my @paragraphs_split;
    for(my $i=0; $i<@paragraphs; $i++) {
	$paragraphs_split[$i]=&sentence_splitter($language,$paragraphs[$i]);
    }
    return join('',@paragraphs_split);
}

sub sentence_splitter {
    my($language,$text)=@_;

    if(exists($lingua_sentence_splitters{$language})) {
	return $lingua_sentence_splitters{$language}->split($text);
    } else {
	my $tmp_file="tmp.$pid.in";
	open(T,">$tmp_file");
	print T $text, "\n";
	close(T);
	my $pipeline=&sentence_splitter_pipeline($language);
	my $split_text=`cat $tmp_file $pipeline`;
	unlink($tmp_file);
	return $split_text;
    }
}

sub concatenate_xml_fields {
    my($xml_fields,$fields,$delimiter)=@_;
    $delimiter||='';
    my @contents;
    for(my $i=0; $i<@$fields; $i++) {
	if(exists($$xml_fields{$fields->[$i]}) 
	   && defined($$xml_fields{$fields->[$i]}) 
	   && $$xml_fields{$fields->[$i]} ne '') {
	    push(@contents,$$xml_fields{$fields->[$i]});
	}
    }

    return join($delimiter,@contents);
}

sub return_xml_tag_value {
    my($xml,$tag)=@_;

    my $value='';
    if(exists($$xml{$tag}) && defined($$xml{$tag})) {
	$value=$$xml{$tag};
	$value=~s/\n/\t/g;
    }
    return $value;
}

sub get_xml_fields {
    my($lines,$xml_fields)=@_;
    my $field_error=0;
    my $current_field;
    my @buffer;
    for(my $i=0; $i<@$lines; $i++) {
        #print STDERR $lines->[$i];
	if($lines->[$i]=~/^<\?xml version/) {
	    next;
	} elsif($lines->[$i]=~/^[\s\t]*<doc url=\"([^\"]+)\">/) {
	    $$xml_fields{'url'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<main value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'http'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<http value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'http'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<source value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'source'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<date value=\"([0-9\-]+)\"\/\>/) {
	    $$xml_fields{'date'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<id value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'id'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<language value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'language'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<encoding value=\"([^\"]+)\"\/\>/) {
	    $$xml_fields{'encoding'}=$1;
	} elsif($lines->[$i]=~/^[\s\t]*<genre>/) {	    
	    $current_field='genre';
	} elsif($lines->[$i]=~/^[\s\t]*<keywords>/) {	    
	    $current_field='keywords';
	} elsif($lines->[$i]=~/^[\s\t]*<categories>/) {	    
	    $current_field='categories';
	} elsif($lines->[$i]=~/^[\s\t]*<headline>/ || $lines->[$i]=~/^[\s\t]*<headlines>/) {	    
	    $current_field='headline';
	} elsif($lines->[$i]=~/^[\s\t]*<description>/) {	    
	    $current_field='description';
	} elsif($lines->[$i]=~/^[\s\t]*<images>/) {	    
	    $current_field='images';
	} elsif($lines->[$i]=~/^[\s\t]*<captions>/) {	    
	    $current_field='captions';
	} elsif($lines->[$i]=~/^[\s\t]*<body>/) {
	    $current_field='body';
	} elsif($lines->[$i]=~/^[\s\t]*<\/([^\>]+)>[\s\t]*\n/) {
	    my $tag_name=$1;
	    if($tag_name ne 'doc' && !defined($current_field)) {
		print STDERR "Current field not defined for: $lines->[$i]";
		print STDERR "Ignoring document $$xml_fields{'url'}\n";
		$field_error=1;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/keywords>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/genre>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/categories>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/headline>/ || $lines->[$i]=~/^[\s\t]*<\/headlines>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/description>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/images>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/captions>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    } elsif($lines->[$i]=~/^[\s\t]*<\/body>/) {
		$$xml_fields{$current_field}=join('',@buffer);
		undef @buffer;
		undef $current_field;
	    }
	} else {
	    push(@buffer,$lines->[$i]);
	}
    }
    #print STDERR $field_error; 
    if(!exists($$xml_fields{'source'})) {
	if(exists($$xml_fields{'url'}) && $$xml_fields{'url'}=~/^(CNA|NYT|XIN|AFP|APW|WPB|SLN|UME|WSJ|REU|LTW)[\_\.0-9]/) {
	    $$xml_fields{'source'}=$1;
	}
    }
}



sub fullfills_date_restrictions {
    my($date)=@_;

    my $exclude=0;
    if($dates_to_be_excluded) {
	foreach my $exclude_date (keys %exclude_dates) {
	    if($date=~/^$exclude_date/) {
		$exclude=1;
		last;
	    }
	}
    }

    return 0 if($exclude);

    if($dates_to_be_included) {
	$exclude=1;
	foreach my $include_date (keys %include_dates) {
	    if($date=~/^$include_date/) {
		$exclude=0;
		last;
	    }
	}
    }
    if($exclude) {
	return 0;
    } else {
	return 1;
    }
}

sub fullfills_language_restrictions {
    my($language)=@_;

    my $include=0;
    for(my $i=0; $i<@languages; $i++) {
	if($languages[$i] eq 'all') {
	    $include=1;
	    last;
	} elsif($languages[$i] eq $language) {
	    $include=1;
	    last;
	}
    }
    return $include;
}



sub set_exclusion_dates {
    my($exclude_dates,$exclude_dates_string)=@_;

    my $dates_to_be_excluded=0;
    if($exclude_dates_string=~/^file:(.+)$/) {
	my $exclude_dates_file=$1;
	open(F,"<$exclude_dates_file")||die("can't open $exclude_dates_file: $!\n");
	while(defined(my $line=<F>)) {
	    if($line=~/^[0-9]/) {
		chomp($line);
		my @dates_tmp=split(/\,/,$line);
		for(my $i=0; $i<@dates_tmp; $i++) {
		    $$exclude_dates{$dates_tmp[$i]}=1;
		}
		if(@dates_tmp>0) {
		    $dates_to_be_excluded=1;
		}
	    }
	}
    } else {
	my @dates_tmp=split(/\,/,$exclude_dates_string);
	if(@dates_tmp>0) {
	    $dates_to_be_excluded=1;
	}
	for(my $i=0; $i<@dates_tmp; $i++) {
	    $$exclude_dates{$dates_tmp[$i]}=1;
	}
    }
    return $dates_to_be_excluded;
}


sub set_inclusion_dates {
    my($include_dates,$include_dates_string)=@_;
    my $dates_to_be_included=0;

    if($include_dates_string=~/^file:(.+)$/) {
	my $include_dates_file=$1;
	open(F,"<$include_dates_file")||die("can't open $include_dates_file: $!\n");
	while(defined(my $line=<F>)) {
	    if($line=~/^[0-9]/) {
		chomp($line);
		my @dates_tmp=split(/\,/,$line);
		for(my $i=0; $i<@dates_tmp; $i++) {
		    $$include_dates{$dates_tmp[$i]}=1;
		}
		if(@dates_tmp>0) {
		    $dates_to_be_included=1;
		}
	    }
	}
    } else {
	my @dates_tmp=split(/\,/,$include_dates_string);
	if(@dates_tmp>0) {
	    $dates_to_be_included=1;
	}
	for(my $i=0; $i<@dates_tmp; $i++) {
	    $$include_dates{$dates_tmp[$i]}=1;
	}
    }
    return $dates_to_be_included;
}

sub map_language {
    my($language)=@_;
    my($general,$specific)=split(/\_/,$language);
    if(!$convert_trad2simp && $specific=~/^(traditional|simplified)$/) {
	return $language;
    } else {
	return $general;
    }
}


sub sentence_splitter_pipeline {
	return "\| $Bin/./sentence-splitter-foreign-no-uppercase.pl";	
}

sub read_doc_info {
    my($handle,$info_file,$doc_info)=@_;

    if($info_file=~/\.gz$/) {
        open $handle, "<:gzip", $info_file, or die("can't open file $info_file: $!\n");
    } else {
        open($handle,"<$info_file")||die("can't open file $info_file: $!\n");
    }

    while(defined(my $line=$handle->getline)) {
	chomp($line);
	my(@fields)=split(/ \|\|\| /o,$line);
	my($url)=$fields[0]=~/^file\=\"([^\"]*)\"/;
	$$doc_info{$url}=$line;
    }
    close($handle);
}


sub add_doc_info_entry {
    my($xml_fields,$file_name,$doc_info,$tags,$output_file)=@_;
    my @values;
    for(my $i=0; $i<@$tags; $i++) {
	my $value=&remove_whitespace(&return_xml_tag_value($xml_fields,$tags->[$i]));
	push(@values,"$tags->[$i]\=\"$value\"");
    }
    my @fields;
    foreach my $field (sort (@values)) {
	push(@fields,$field);
    }
    unshift(@fields,"file=\"$file_name\"");
    my $entry=join(' ||| ',@fields);
    if(defined($output_file)) {
	return $entry;
    } else {
	$$doc_info{$$xml_fields{'language'}}{$file_name}=$entry;
	return 1;
    }
}

sub write_doc_info {
    my($handle,$info_file,$doc_info)=@_;

    if($info_file=~/\.gz$/) {
        open $handle, ">:gzip", $info_file, or die("can't open file $info_file: $!\n");
    } else {
        open($handle,">$info_file")||die("can't open file $info_file: $!\n");
    }

    foreach my $url (sort (keys %$doc_info)) {
	print $handle $$doc_info{$url}, "\n";
    }
    close($handle);
}

sub initialize_languages {
    my($lang_string,$languages)=@_;
    undef @$languages;
    my @args=split(/\,/,$lang_string);
    my %lang_hash;
    for(my $i=0; $i<@args; $i++) {
	if($args[$i] eq 'all') {
	    $languages->[0]='all';
	    return 1;
	} else {
	    $lang_hash{$args[$i]}=1;
	}
    }
    foreach my $lang (sort (keys %lang_hash)) {
	push(@$languages,$lang);
    }
    return 1;
}


sub remove_empty_lines {
    my($text)=@_;

    my @buffer_in=split(/\n+/,$text);
    my @buffer_out;
    for(my $i=0; $i<@buffer_in; $i++) {
	if($buffer_in[$i]!~/^[\s\t]*$/) {
	    push(@buffer_out,"$buffer_in[$i]\n");
	}
    }
    return join('',@buffer_out);
}


sub remove_whitespace {
	my($string)=@_;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}


sub unchomp {
    my($text)=@_;
    if($text!~/\n$/) {
	return "$text\n";
    } else {
	return $text;
    }
}

