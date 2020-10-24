#! /usr/bin/env perl
# -*- coding: utf-8 -*-

use strict;
use warnings;
use utf8;
use Getopt::Long;

use Encode qw(decode encode from_to);
use Text::CSV_XS;
use File::Path qw(mkpath);
use FreePWING::FPWUtils::FPWParser;

my $FNAME_ENCODING = 'utf-8';
my $TERM_ENCODING = 'utf-8';
my $OUTPUT_DIR = ".";

my %SKIP_WORD = (
    a => 1,
    an => 1,
    and => 1,
    at => 2,
    by => 2,
    for => 2,
    in => 2,
    on => 2,
    or => 1,
    the => 1,
    to => 2
);

my %CATALOGS = (
    "ＥＤＩＣ２英和" => [ 2001, "EDIC2D01", 1, "E-DIC英和辞典.csv" ],
    "ＥＤＩＣ２和英" => [ 3001, "EDIC2D02", 1, "E-DIC和英辞典.csv" ],
    "科学技術用語辞典" => [ 2001, "EDIC2D03", 1, "科学技術用語辞典.csv" ],
    "アメリカ口語辞典" => [ 2001, "EDIC2D04", 1, "アメリカ口語辞典.csv" ],
    "英和イディオム完全対訳辞典" => [ 2001, "EDIC2D05", 1,
				      "英和イディオム完全対訳辞典.csv" ],
    "動詞を使いこなすための英和活用辞典" => [ 2001, "EDIC2D06", 1,
					      "動詞を使いこなすための英和活用辞典.csv" ],
    "米英俗語辞典" => [ 2001, "EDIC2D07", 1, "米英俗語辞典.csv" ],
    "会話作文　英語表現辞典" => [ 2001, "EDIC2D08", 1, "会話作文 英語表現辞典.csv" ],
    "対話例文　最新和英口語辞典" => [ 3001, "EDIC2D09", 1,
				     "対話例文 最新和英口語辞典.csv" ],
    "最新日米口語辞典" => [ 2001, "EDIC2D10", 1, "最新日米口語辞典.csv" ],
    "新語・流行語小辞典" => [ 2001, "EDIC2D11", 1, "新語・流行語小辞典.csv" ],
    "ニュース英語例文集" => [ 2001, "EDIC2D12", 1, "ニュース英語例文集.csv" ],
    "現代用語例文集" => [ 2001, "EDIC2D13", 2, "現代用語例文集.csv" ],
    "海外生活英会話" => [ 2001, "EDIC2D14", 2, "海外生活英会話.csv" ],
    "ビジネス例文集" => [ 2001, "EDIC2D15", 2, "ビジネス例文集.csv" ],
    "ビジネスｅメール例文集" => [ 2001, "EDIC2D16", 2, "ビジネスｅメール例文集.csv" ],
    "社内ｅメール例文集" => [ 2001, "EDIC2D17", 2, "社内ｅメール例文集.csv" ],
    "オフィスの英語フレーズ集" => [ 2001, "EDIC2D18", 2, "オフィスの英語フレーズ集.csv" ],
    "経済・金融例文集" => [ 2001, "EDIC2D19", 2, "経済・金融例文集.csv" ],
    "科学ニュース例文集" => [ 2001, "EDIC2D20", 2, "科学ニュース例文集.csv" ],
    "工業英語例文集" => [ 2001, "EDIC2D21", 2, "工業英語例文集.csv" ],
    "技術ビジネス英語例文集" => [ 2001, "EDIC2D22", 2, "技術ビジネス英語例文集.csv" ],
    "特許英語例文集" => [ 2001, "EDIC2D23", 2, "特許英語例文集.csv" ],
    "医学英語例文集" => [ 2001, "EDIC2D24", 2, "医学英語例文集.csv" ],
    "エンジニア例文集" => [ 2001, "EDIC2D25", 3, "エンジニア例文集.csv"  ],
    "新語・流行語小辞典２" => [ 2001, "EDIC2D26", 3, "新語・流行語小辞典２.csv" ],
    );

 MAIN:
{
    my $PROGRAM_NAME = $0;
    my $make_catalog = '';
    if (!GetOptions('catalogs=s' => \$make_catalog)) {
	exit 1;
    }
    if ($make_catalog) {
	make_catalog($make_catalog);
    } else {
	convert($ARGV[0], $ARGV[1]);
    }
}

sub utf2euc {
  my ($text) = @_;
  $text =~ s/～/〜/g; # FULLWIDTH THILDA -> WAVE DASH
  $text =~ s/①/(1)/g;
  $text =~ s/②/(2)/g;
  $text =~ s/③/(3)/g;
  $text =~ s/④/(4)/g;
  $text =~ s/⑤/(5)/g;
  $text =~ s/⑥/(6)/g;
  $text =~ s/⑦/(7)/g;
  $text =~ s/⑧/(8)/g;
  $text =~ s/⑨/(9)/g;
  $text =~ s/⑩/(10)/g;
  $text =~ s/⑪/(11)/g;
  $text =~ s/⑫/(12)/g;
  $text =~ s/⑬/(13)/g;
  $text =~ s/⑭/(14)/g;
  $text =~ s/⑮/(15)/g;
  $text =~ s/⑯/(16)/g;
  $text =~ s/⑰/(17)/g;
  $text =~ s/⑱/(18)/g;
  $text =~ s/⑲/(19)/g;
  $text =~ s/⑳/(20)/g;
  $text = encode('euc-jp', $text);
  $text =~ s/\x8F[\xA1-\xFE][\xA1-\xFE]/?/g;
  # Workaround
  $text =~ s/\x7f/?/g;
  return $text;
}

sub trim {
    $_ = shift;
    return $_ unless defined($_);
    s/^[\n\s]*(.*?)[\n\s]*$/$1/;
    return $_;
}

sub parse_key {
    $_ = shift;
    return $_ ? parse_en_phrase($_) : ();
}

sub pretty_index {
    $_ = shift;
    die unless defined($_);
    s/\s*\|\s*$//;
    s/^\s*\|\s*//;
    return $_;
}

sub parse_index {
    my ($index_str) = @_;
    my ($en_index_str, $ja_index_str) = split /\s*\|\s*/, $index_str, 2;
    $en_index_str = trim($en_index_str);
    $ja_index_str = trim($ja_index_str);
    my @en_phrases = map { expand_en_optional_phrase($_) }
	$en_index_str ? parse_en_phrase($en_index_str) : ();
    my @ja_phrases =
	$ja_index_str ? parse_ja_phrase($ja_index_str) : ();
    return \@en_phrases, \@ja_phrases;
}

sub parse_en_phrase {
    $_ = shift;
    return split /\s*,\s*/;
}

sub expand_en_optional_phrase {
    $_ = shift;
    return () unless defined($_);
    if (/\([^)]+\)|\[[^\]]+\]/) {
        my $p1 = trim($`);
        my $p2 = trim($`) . substr($&, 1, -1);
        my $left = $';
	my @result;
	for my $phrase (expand_en_optional_phrase($left)) {
	    push @result, $p1 . $phrase;
	    push @result, $p2 . $phrase;
	}
	return @result;
    }
    return (trim($_));
}

sub parse_ja_phrase {
    $_ = shift;
    if (/［([^］]+)］\s*$/) {
        return (expand_ja_optional_phrase(trim($`)),
		parse_ja_alternative($1));
    }
    return expand_ja_optional_phrase($_);
}

sub expand_ja_optional_phrase {
    $_ = shift;
    if (/(（[^）]+）|［[^］]+］)/) {
	my $p1 = trim($`);
        my $p2 = $` . substr($&, 1, -1);
        my $left = $';
	my @result;
	for my $phrase (expand_ja_optional_phrase($left)) {
            push @result, $p1 . $phrase;
            push @result, $p2 . $phrase;
	}
	return @result;
    }
    return (trim($_));
}

sub parse_ja_alternative {
    $_ = shift;
    my @phrases = split /\s*[\|、・]\s*/;
    if (scalar @phrases > 1) {
	return @phrases;
    }
    return (trim($_));
}

use vars qw($entry_no);
$entry_no = 0;
sub row_to_epwing {
    return if (scalar(@_) < 7);
    my ($fpw, $id, $subid, $speech, $key, $index, $comment, @rest) = @_;

    if ($index) {
	my $fpwtext = $fpw->{text};
	my $fpwheading = $fpw->{heading};
	my $fpwword2 = $fpw->{word2};
	my $fpwkeyword = $fpw->{keyword};
	my $science = $fpw->{science};
	
        my @key_phrases = parse_key($key);
        my ($en_phrases, $ja_phrases) = parse_index($index);

	# new entry
	$fpwtext->new_entry()
	    or die $fpwtext->error_message() . "\n";
	$fpwheading->new_entry()
	    or die $fpwheading->error_message() . "\n";

	# add heading
	my $heading_text = pretty_index($science ? $en_phrases->[0] : $index);
	$fpwheading->add_text(utf2euc($heading_text))
	    or die $fpwheading->error_message() . "\n";
	$fpwtext->add_entry_tag($id);
	print "Entry: $entry_no; ".encode($TERM_ENCODING, $heading_text)."\n";
	$entry_no++;

	# add key text
	if (!$fpwtext->add_keyword_start() ||
	    !$fpwtext->add_text(utf2euc($key ? $key : $heading_text)) || 
	    !$fpwtext->add_keyword_end() ||
	    !$fpwtext->add_newline()) {
	    die $fpwtext->error_message() . "\n";
	}

	# add index
	my $heading_position = $fpwheading->entry_position();
	my $text_position = $fpwtext->entry_position();
	my @words = ();
        for my $phrase (@key_phrases, @$en_phrases, @$ja_phrases) {
	    next if $phrase eq '';
	    $fpwword2->add_entry(utf2euc($phrase),
				 $heading_position, $text_position)
		or die $fpwword2->error_message() . "\n";
	    my $w = $phrase;
	    $w =~ s/[^-'a-zA-Z0-9\s]//g;
	    if (length(trim($w)) == 0) {
		$w = $phrase;
	    } else {
		$w =~ tr/A-Z/a-z/;
	    }
	    @words = (@words, map &trim, split / +/, $w);
	}

	# add keywords
	if ($fpwkeyword) {
	    # remove duplicated words
	    my %words;
	    for (@words) {
		next unless defined($_);
		$words{$_} = 1;
	    }
	    @words = keys %words;
	    
	    # remove empyt words
	    @words = grep /[^ ]*/, @words;

	    # remove skip words
	    @words = grep { !defined($SKIP_WORD{$_}) ||
				$SKIP_WORD{$_} != 1 } @words;
	    @words = grep { !defined($SKIP_WORD{$_}) } @words
		if (scalar @words >= 5);
	    
	    for (sort @words) {
		next if length($_) == 0;
		$fpwkeyword->add_entry(utf2euc($_), $heading_position, $text_position)
		    or die $fpwkeyword->error_message() . "\n";
	    }
	}

	# add text
	for my $line (split /<CR>/, ($science ? $index : $comment)) {
	    while ($line =~ /▲▲(.+?)\/(\d{11})△△/) {
		my $prev = $`;
		my $lt = $1;
		my $target = $2;
		$fpwtext->add_text(utf2euc($prev))
		    or die $fpwtext->error_message() . "\n";
		if (substr($id, 0, 3) eq substr($target, 0, 3)) {
		    # bookid が一致
		    if (!$fpwtext->add_reference_start() ||
			!$fpwtext->add_text(utf2euc($lt)) ||
			!$fpwtext->add_reference_end($target)) {
			die $fpwtext->error_message() . "\n";
		    }
		} else {
		    # 別文献への jump はサポートしない
		    print "  !!remove jump to $target\n";
		    if (!$fpwtext->add_emphasis_start() ||
			!$fpwtext->add_text(utf2euc($lt)) ||
			!$fpwtext->add_emphasis_end()) {
			die $fpwtext->error_message() . "\n";
		    }
		}
		$line = $';
	    }
	    if (!$fpwtext->add_text(utf2euc($line)) ||
		!$fpwtext->add_newline()) {
		die $fpwtext->error_message() . "\n";
	    }
	}
    }
}

sub convert {
    my ($dicno, $path_to_directory) = @_;

    opendir(my $DIR, $path_to_directory);
    my @dictname = grep { $CATALOGS{$_}->[1] eq $dicno } keys %CATALOGS;
    die "$dicno is not found, or many exists" if scalar @dictname != 1;
    my $dictname = $dictname[0];
    my $csvname = $CATALOGS{$dictname}->[3];
    
    for my $fname (map { decode($FNAME_ENCODING, $_) } readdir $DIR) {
	my $path = "$path_to_directory/$fname";
        if (-f $path && $path =~ /\.csv$/) {
	    next unless $path =~ /$csvname$/;
            print encode($TERM_ENCODING, "[$path]\n");
	    my %fpw;
	    $fpw{science} = ($dictname eq '科学技術用語辞典') ? 1 : 0;
	    
	    initialize_fpwparser(
		text => \$fpw{text},
		heading => \$fpw{heading},
		word2 => \$fpw{word2},
		keyword => \$fpw{keyword});
	    
	    my $csv = Text::CSV_XS->new({ binary => 1 });
	    open my $INPUT, "<:encoding(utf-8)", $path;
	    $csv->getline($INPUT); # skip first line
	    while (my $row = $csv->getline($INPUT)) {
		row_to_epwing(\%fpw, @$row);
	    }
	    close $INPUT;

	    finalize_fpwparser(
		text => \$fpw{text},
		heading => \$fpw{heading},
		word2 => \$fpw{word2},
		keyword => \$fpw{keyword});
	}
    }
    closedir $DIR;
}

sub make_catalog {
    my $dicno = shift;
    my @dictname = grep { $CATALOGS{$_}->[1] eq $dicno } keys %CATALOGS;
    die "$dicno is not found, or many exists" if scalar @dictname != 1;
    my $dictname = $dictname[0];
    
    open my $OUTPUT, ">:encoding(euc-jp)", "catalogs.txt";
    print $OUTPUT <<"EOS";
[Catalog]
Filename   = catalogs
Type       = EPWING1
Books      = 1

[Book]
Title      = "$dictname"
BookType   = $CATALOGS{$dictname}->[0]
Direcotry  = "$CATALOGS{$dictname}->[1]"
EOS
    close $OUTPUT;
}
