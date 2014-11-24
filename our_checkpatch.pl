#!/usr/bin/perl -w
#
# Created by Georgios Koloventzos
# Columbia University - CS department
#
use File::Basename;
use Term::ANSIColor;# qw(:constants);
use Getopt::Long;
local $Term::ANSIColor::AUTORESET = 1;

sub error_found{
  print colored(['on_red'], $_[0]. "\n");
  print color('reset');
  exit 1;
}

sub checkpatch_error{

  print "Error at file $_[0] around $_[1]: $_[2]\n";
  unless ($_[4]) {
    print colored(['blue'], $_[3]);
    return;
  }
  my $line = $_[4] - 6;
  print colored(['blue'], "At line: $line -- $_[3]");
}

#if ($#ARGV == 0 and ($ARGV[0] =~ m/-h/ or $ARGV[0] !~ m/^[0-9a-f]{40}$/)) {
#	print "Usage: ours_checkpatch.pl SHA\n";
#	exit 0;
#}
my $git = `which git 2>&1`;
if ($? != 0) {
  error_found($git);
}
chomp $git;
my $wget = `which wget 2>&1`;
my $wget_exit = $?;
chomp $wget;

my $touch = `which touch 2>&1`;
my $touch_exit = $?;

unless ( -d "./.git" ) {
	error_found("You should run this scipt in the top directory of the kernel");
}

unless ( -e "checkpatch.pl") {
  if ($wget_exit != 0) {
    error_found($wget);
  }
  $checkpatch_wget = `$wget "https://raw.githubusercontent.com/torvalds/linux/master/scripts/checkpatch.pl" 2>&1`;
  if ($? != 0) {
    error_found($checkpatch_wget);
  }
}

$mode = 0755;
chmod $mode, "checkpatch.pl";

unless ( -e "spelling.txt") {
  if ($touch_exit != 0) {
    error_found($touch);
  }
  $touch_spelling = `$wget https://raw.githubusercontent.com/torvalds/linux/master/scripts/spelling.txt 2>&1`;
  if ($? != 0) {
    error_found($touch_spelling);
  }
}

#finding first commit no longer needeed
my @TAs = ();

my $rev_list;
my $rev_hash_f;
my $found;
print colored(['on_red'], "Searching for first commit with no TAs mail");
$rev_list = `git rev-list HEAD --reverse`;
print "\n";
foreach my $rev_hash (split /\n/, $rev_list) {
  my $oo = `git --no-pager show -s --format='%ae' $rev_hash`;
  chomp $oo;
  $found = 0;
  foreach my $TA (@TAs) {
    if ($oo eq $TA) {
      $rev_hash_f = $rev_hash;
      $found = 1;
      last;
    }
  }
  unless ($found) {
    last;
   }
}

if ($found) {
  error_found("NO STARTING hash. Either you are in the correct year or not in OS course");
}
print colored(['green'], "Commit found: $rev_hash_f\n");

my $diff_output = "srcdiff";
`git diff $rev_hash_f -- '*.c' '*.h' '*.S' > $diff_output`;
if ( -z $diff_output) {
  exit 0;
}
my $checkpatch_output = `./checkpatch.pl --ignore FILE_PATH_CHANGES -terse --no-signoff -no-tree $diff_output`;


#parsing checkpatch output
#
open my $CHECKPATCH, $diff_output or error_found("Cannot open file: $diff_output");
my @split;
my @checkpatch_errors  = split /\n/, $checkpatch_output;
my $errors = {};
my $last_line = "";
foreach my $line (@checkpatch_errors) {
  @split = split(/:/, $line, 3);
  if (@split == 3) {
    $errors{$split[1]} = $split[2];
  } else {
    $last_line = $line;
  }
}

my $error_file;
my $lines_affected;
my $new_file = 0;
my $created_file = 0;
while (<$CHECKPATCH>) {
  if (/^new/) {
    $created_file++;
  }
  $created_file++ if ($created_file > 0);
  if (/^\+\+\+/) {
    $created_file = 0 if ($created_file > 5);
    $error_file = $_;
    $error_file =~ s/\+\+\+ b/\./;
    chomp $error_file;
    $new_file = 1;
    next;
  }
  if ($new_file) {
    $lines_affected = $_;
    chomp $lines_affected;
    $new_file = 0;
  }
  checkpatch_error($error_file, $lines_affected, $errors{$.}, $_, $created_file) if exists $errors{ $. };
}

if ($last_line ne '') {
  print colored(['yellow'], $last_line . "\n");
} else {
  print colored(['green'], "Everything clear\n");
}

exit 0;
