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

# File::RandomLine must be installed!
$WIKTIONARY_URL = "http://dumps.wikimedia.org/enwiktionary/20131217/enwiktionary-20131217-all-titles.gz";

$LAST_NAME_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.all.last";
$FIRST_NAME_FEMALE_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.female.first";
$FIRST_NAME_MALE_URL = "http://www.census.gov/genealogy/www/data/1990surnames/dist.male.first";

$LAST_NAME_FILE =$FindBin::Bin."/db/lname.dat";
$FEMALE_FIRST_NAME_FILE = $FindBin::Bin."/db/fnamef.dat";
$MALE_FIRST_NAME_FILE = $FindBin::Bin ."/db/fnamem.dat";
$WIKTIONARY_NAME_FILE = $FindBin::Bin . "/db/enwiktionary-all-titles.filtered";
make_path("db");

$FEMALE_PCT = 0.5; # 50%

my $bDownload = 0;
my $bUser = 0;
my $bHelp= 0;
my $bInteractive = 0;
my $iShuffleMode =0;

GetOptions(
	'mode=i' => \$iShuffleMode,
	'download!' => \$bDownload,
	'usernames!'     => \$bUser,
	'interactive!'     => \$bInteractive,
	'help!'     => \$bHelp,
) or die "Incorrect usage!\n";

if( $bHelp ) {
	print "Common on, it's really not that hard.\n";
} 

if ($#ARGV != 0 ) {
	print "Usage: namegen.pl [-d] <# of names>\n";
	print "-u \tgenerate usernames";
	exit 1;
}
$num_names = $ARGV[0];

if (!(-f $LAST_NAME_FILE && -f $MALE_FIRST_NAME_FILE && -f $FEMALE_FIRST_NAME_FILE) && -f $WIKTIONARY_NAME_FILE &&  !$bDownload) {
	print "First time you run this, use the -d option to download name files from the census.\n";
	exit 1;
}

if ($bDownload) {
	download($LAST_NAME_URL, $LAST_NAME_FILE, "last name census data");
	download($FIRST_NAME_FEMALE_URL, $FEMALE_FIRST_NAME_FILE, "female first name census data");
	download($FIRST_NAME_MALE_URL, $MALE_FIRST_NAME_FILE, "male first name census data");
	download($WIKTIONARY_URL, $WIKTIONARY_NAME_FILE . "raw.gz", "Wiktionary name dump. [takes a while]");
	# extract and unpack wiki
	print "Extracting wikionary data\n";
	system("gunzip $WIKTIONARY_NAME_FILE"."raw.gz");
	system("egrep -v [^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ] $WIKTIONARY_NAME_FILE"."raw > $WIKTIONARY_NAME_FILE ");
	system("rm $WIKTIONARY_NAME_FILE"."raw");
}

my @lnames = makeNameArray($LAST_NAME_FILE);
my @fnamefs = makeNameArray($FEMALE_FIRST_NAME_FILE);
my @fnamems = makeNameArray($MALE_FIRST_NAME_FILE);

my $wiki = File::RandomLine->new($WIKTIONARY_NAME_FILE);



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
			if($userword eq "n" ){
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

sub printList{
	for($i = 0 ; $i < $num_names; ++$i) {
		# Last name
		$lname = $lnames[int(rand($#lnames + 1))];

		# Male or female?
		$fname = (rand(1) > $FEMALE_PCT) ? $fnamems[int(rand($#fnamems + 1))] : $fnamefs[int(rand($#fnamefs + 1))];

		if( $bInteractive ){
			print sprintf("%-5s","[$i]");
		}
		if( $bUser) {
			switch($iShuffleMode){
				case 1 { $tStr = $fname. ".". $lname}
				case 2 { $tStr = $fname. ".". $lname; $tStr = lc($tStr)}
				case 3 { $tStr = $fname. "-". $lname}
				case 4 { $tStr = $fname. "-". $lname; $tStr = lc($tStr)}
				case 5 { $tStr = $fname. "". $lname}
				case 6 { $tStr = $fname. "". $lname; $tStr = lc($tStr)}
				case 7 { $tStr = $wiki->next(). "." .$wiki->next }
				else {  $tStr = $wiki->next()}
			}
		}else{
			$tStr ="$fname $lname";
		}
		print $tStr ."\n";
		if($bInteractive){
			push(@results, $tStr)
		}

	}
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

