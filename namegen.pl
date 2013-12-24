#!/usr/bin/env perl

use warnings;
use LWP::Simple;
use Cwd 'abs_path';
use FindBin;
use File::Spec;
use File::RandomLine;
use File::Path qw(make_path);
use Getopt::Long;
use Switch;
use Term::ANSIColor;

# File::RandomLine must be installed!
$WIKTIONARY_URL = "http://dumps.wikimedia.org/enwiktionary/20131217/enwiktionary-20131217-all-titles.gz";

$LAST_NAME_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.all.last";
$FIRST_NAME_FEMALE_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.female.first";
$FIRST_NAME_MALE_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.male.first";

$LAST_NAME_FILE =$FindBin::Bin."/db/lname.dat";
$FEMALE_FIRST_NAME_FILE = $FindBin::Bin."/db/fnamef.dat";
$MALE_FIRST_NAME_FILE = $FindBin::Bin ."/db/fnamem.dat";
$WIKTIONARY_NAME_FILE = $FindBin::Bin . "/db/enwiktionary-all-titles.filtered";
$ADJECTIVE_FILE= $FindBin::Bin . "/db-own/adjectives.txt";
$NOUN_FILE= $FindBin::Bin . "/db-own/nouns2.txt";
make_path("db");

$FEMALE_PCT = 0.5; # 50%

my $bDownload = 0;
my $bHelp= 0;
my $bRandom= 0;
my $bInteractive = 0;
my $iShuffleMode =0;
my $bColorless = 0;
my $bSpeed = 0;

GetOptions(
	'mode=i' => \$iShuffleMode,
	'download!' => \$bDownload,
	'random!'     => \$bRandom,
	'interactive!'     => \$bInteractive,
	'colorless!'     => \$bColorless,
	'speed!'     => \$bSpeed,
	'help!'     => \$bHelp,
) or die "Incorrect usage!\n";


if ($#ARGV != 0 or $bHelp ) {
	print "Usage: namegen.pl <# of names>\n";
	print "-m \tselect mode\n";
	print "-d \tdownload the database\n";
	print "-i \tinteractive mode\n";
	print "-r \trandomly select a mode\n";
	print "-s \tdo not load in memory -> reduce startup time.\n";
	exit 1;
}
$num_names = $ARGV[0];

if (!(-f $LAST_NAME_FILE && -f $MALE_FIRST_NAME_FILE && -f $FEMALE_FIRST_NAME_FILE) && -f $WIKTIONARY_NAME_FILE &&  !$bDownload) {
	print "First time you run this, use the -d option to download name files from the census.\n";
	exit 1;
}

if ($bDownload) {
	download($LAST_NAME_URL, $LAST_NAME_FILE.".raw", "last name census data");
	download($FIRST_NAME_FEMALE_URL, $FEMALE_FIRST_NAME_FILE.".raw", "female first name census data");
	download($FIRST_NAME_MALE_URL, $MALE_FIRST_NAME_FILE.".raw", "male first name census data");
	print "Converting census data\n";
	# Makes first letter upper, rest lowercase
	system("cat $LAST_NAME_FILE".".raw | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]'  | awk '{ print toupper(substr(\$0, 1, 1)) substr(\$0, 2) }'> $LAST_NAME_FILE");
	system("cat $MALE_FIRST_NAME_FILE".".raw | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]' | awk '{ print toupper(substr(\$0, 1, 1)) substr(\$0, 2) }'  > $MALE_FIRST_NAME_FILE");
	system("cat $FEMALE_FIRST_NAME_FILE".".raw | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]' | awk '{ print toupper(substr(\$0, 1, 1)) substr(\$0, 2) }'> $FEMALE_FIRST_NAME_FILE");
	# go own to download wiktionary
	download($WIKTIONARY_URL, $WIKTIONARY_NAME_FILE . "raw.gz", "Wiktionary name dump. [takes a while]");
	# extract and unpack wiki
	print "Extracting wikionary data\n";
	system("gunzip $WIKTIONARY_NAME_FILE"."raw.gz");
	system("egrep -v '[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]' $WIKTIONARY_NAME_FILE"."raw > $WIKTIONARY_NAME_FILE ");
	system("rm $WIKTIONARY_NAME_FILE"."raw");
}

# use in memory storage if you require fast output of n > 100000 data
# it takes about 3 secs with memory storage
my @lnames,my @fnamefs, my @fnamems,my @wikis, my @nouns, my @adjs;
if (! $bSpeed ){
	@lnames = makeNameArray($LAST_NAME_FILE.".raw");
	@fnamefs = makeNameArray($FEMALE_FIRST_NAME_FILE.".raw");
	@fnamems = makeNameArray($MALE_FIRST_NAME_FILE.".raw");
	@wikis= makeArrayFile($WIKTIONARY_NAME_FILE);
	@nouns= makeArrayFile($NOUN_FILE);
	@adjs= makeArrayFile($ADJECTIVE_FILE);
}

my $Llnames= File::RandomLine->new($LAST_NAME_FILE);
my $Lfnamems= File::RandomLine->new($MALE_FIRST_NAME_FILE);
my $Lfnamefs = File::RandomLine->new($FEMALE_FIRST_NAME_FILE);
my $Lwiki = File::RandomLine->new($WIKTIONARY_NAME_FILE);
my $Ladj= File::RandomLine->new($ADJECTIVE_FILE);
my $Lnoun= File::RandomLine->new($NOUN_FILE);



my @results;

if($bInteractive){
	while( 1){
		@results = ();
		printList();
		# ask for input to copy
		while(1){
			print "\n";
			print "Enter result to copy to clipboard [0-9|q|n]: ";
			my $userword = <STDIN>; 
			chomp $userword;
			if( $userword eq "q"){
				exit 0;
			}
			if($userword eq "n" or $userword eq "" ){
				print "\n";
				last;
			}
			if( $userword ge 0 and $userword lt scalar @results){
				#Clipboard->copy($results[$userword]);
				system("echo -n  $results[$userword] | xsel -b");
				print "$results[$userword] copied to clipboard\n"; 
				exit 0;
			}
		}
	}
}else{
	printList();
}

sub colorwrap(){
	if ( $bColorless) {
		return $_[0];
	}else{
		return colored($_[0], $_[1]);
	}
}

sub printList{
	for($i = 0 ; $i < $num_names; ++$i) {
			# Last name
		$lname = &wrapper_array(2); 

		# Male or female?
		$fname = (rand(1) > $FEMALE_PCT) ? &wrapper_array(1): &wrapper_array(2);

		# other variables: names, adj, wiki
		$wiki = wrapper_array(4);
		$noun = wrapper_array(5);
		$adj = wrapper_array(6);

		if( $bInteractive ){
			print sprintf("%-5s","[$i]");
		}

		if($bRandom){
			# do not include modes with whitespace
			$max = 10-1;
			$iShuffleMode = int(rand($max))+1;
		}
		switch($iShuffleMode){
			case 1 { $tStr = &colorwrap( $fname, 'magenta'). ".". &colorwrap($lname, 'blue')}
			case 2 { $tStr = &colorwrap( $fname, 'magenta'). ".". &colorwrap($lname, 'blue') ;$tStr = lc($tStr)}
			case 3 {  $tStr = &colorwrap( $fname, 'magenta'). "-". &colorwrap($lname, 'blue') }
			case 4 {  $tStr = &colorwrap( $fname, 'magenta'). "-". &colorwrap($lname, 'blue') ; $tStr = lc($tStr)}
			case 5 {  $tStr = &colorwrap( $fname, 'magenta'). "". &colorwrap($lname, 'blue') }
			case 6 {  $tStr = &colorwrap( $fname, 'magenta'). "". &colorwrap($lname, 'blue') ; $tStr = lc($tStr)}
			case 7 { $tStr = &colorwrap($wiki, 'green')}
			case 8 {$tStr = &colorwrap( $wiki, 'green'). "". &colorwrap($wiki, 'yellow') ; $tStr = lc($tStr) }
			case 9 { $tStr = &colorwrap( $wiki, 'green'). "". &colorwrap($wiki, 'yellow')  }
			case 10 { $tStr = &colorwrap( $wiki, 'green'). "". &colorwrap($wiki, 'yellow') ; $tStr = lc($tStr)}
			case 11 { $tStr = &colorwrap( $adj, 'green'). "". &colorwrap($noun, 'yellow') ;}
			case 12 { $tStr = &colorwrap( $adj, 'green'). "". &colorwrap($lname, 'yellow') ; } 
			else {   $tStr = &colorwrap( $fname, 'magenta'). " ". &colorwrap($lname, 'blue')  } 
		}

		print "$tStr\n";
		#print $tStr ."\n";
		if($bInteractive){
			push(@results, $tStr)
		}

	}
}

sub wrapper_array(){
	switch($_[0]){
		case 0 {
			if(!$bSpeed) { return getrandom(\@lnames)} else { return $Llnames->next(); }
		 }
		case 1{
			if(!$bSpeed) { return getrandom(\@fnamems) } else { return $Lfnamems->next(); }
		 }
		case 2 {
			if(!$bSpeed) { return getrandom(\@fnamefs) } else { return $Lfnamefs->next(); }
		 }
		case 4{
			if(!$bSpeed) { return getrandom(\@wikis) } else { return $Lwiki->next(); }
		 }
		case 4{
			if(!$bSpeed) { return getrandom(\@nouns) } else { return $Lnoun->next(); }
		 }
		case 5{
			if(!$bSpeed) { return getrandom(\@adjs) } else { return $Ladj->next(); }
		 }
	}
}

sub getrandom(){
	@arr =\$_[0];
	$ret = $_[0][int(rand($#arr+ 1))]; 
	return $ret;
}

sub download{
	$url = $_[0];
	$file = $_[1];
	$desc = $_[2];
	++$|;
	print "Downloading " . $desc . "... ";
	getstore($url, $file) or die "Unable to download " . $desc . " (" . $url . ")\n";
	print "Done.\n";
}

# from: https://github.com/carterpage/census-name-generator
sub makeNameArray {
	$file = $_[0];
	my @names;
	open(FILE, $file);
	while(<FILE>) {
		chomp;

		# First column (1-15) is the name.  Format it.
		$name = substr $_, 0, 15;
		$name =~ s/\s//g;
		$name = ucfirst(lc($name));

		# Second column (16-20) is the % distribution of this name in the population.
		$count = substr $_, 16, 5;
		$count = int($count * 1000 + 0.5);

		# Add name to the array in a quantity relative to the % distribution.
		for(my $i = 0 ; $i < $count ; ++$i) {
			push(@names, $name);
		}
	}
	return @names;
}


sub makeArrayFile{
	$file = $_[0];
	my @names;
	open(FILE, $file);
	while(<FILE>) {
		chomp;

		$name = $_;
		push(@names, $name);
	}
	return @names;
}
