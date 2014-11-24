#!/usr/bin/perl -w
use File::Basename;
use Term::ANSIColor;# qw(:constants);
use Getopt::Long;
local $Term::ANSIColor::AUTORESET = 1;

sub error_found{
  print colored(['on_red'], $_[0]);
  print color('reset');
  print color('reset');
  exit 1;
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

my $touch = `which touch 2>&1`;
my $touch_exit = $?;

unless ( -d "./.git" ) {
	error_found("You should run this scipt in the top directory of the kernel\n");
}

unless ( -e "checkpatch.pl") {
  if ($wget_exit != 0) {
    error_found($wget);
  }
  chomp $wget;
  $checkpatch_wget = `$wget "https://raw.githubusercontent.com/torvalds/linux/master/scripts/checkpatch.pl" 2>&1`;
  if ($? != 0) {
    error_found($checkpatch_wget);
  }
}

unless ( -e "spelling.txt") {
  if ($touch_exit != 0) {
    error_found($touch);
  }
  chomp $touch;
  $touch_spelling = `touch spelling.txt`;
  if ($? != 0) {
    error_found($touch_spelling);
  }
}

#finding first commit no longer needeed

my $rev_list;
my $rev_hash_f;
my $found;
unless (defined $ARGV[0]) {
	print colored(['on_red'], "Searching for first commit with no TAs mail");
	$rev_list = `git rev-list HEAD --reverse`;
	print "\n";
	foreach my $rev_hash (split /\n/, $rev_list) {
    $found = 0;
		my $oo = `git --no-pager show -s --format='%ae' $rev_hash`;
    foreach my $TA (@TAs) {
		  if ($oo =~ /$TA/) {
			  $rev_hash_f = $rev_hash;
        $found = 1;
      }
      if ($found) {
			  last;
      }
		}
	}
}

unless ($found) {
  error_found("NO STARTING hash. Either you are in the correct year or not in OS course\n");
}

print "found: = $found \n";
print $rev_hash_f;
my $diff_output = "srcdiff";
`git diff $rev_hash_f -- '*.c' '*.h' '*.S' > $diff_output`;
if ( -z $diff_output) {
  exit 0;
}
my $checkpatch_output = `perl checkpatch.pl --ignore FILE_PATH_CHANGES -terse --no-signoff -no-tree $diff_output`;

#my $hash = $ARGV[0] ? $ARGV[0] : $rev_hash_f;
#unistd.h has problem with the + signs
#print GREEN "Starting from commit with hash $hash\n";
#my $skip = "flo-kernel/arch/arm/include/asm/unistd.h";
#my $checkpath = "flo-kernel/scripts/checkpatch.pl";
#my $out = `git diff --name-only $hash HEAD`;
#my $gdiff = "--ignore FILE_PATH_CHANGES -terse --no-signoff -no-tree";
#my @lines = split /\n/, $out;
#foreach my $line (@lines) {
#	unless (-B $line) {
#		if (exists $skip_list{$line}) {
#			my $file = basename($line);
#			$std = `git diff $hash -- $line > /tmp/$file`;
#			$stdout =
#			`$checkpath $gdiff /tmp/$file`;
#			`rm -f /tmp/$file`;
#		} else {
#			$stdout = `$checkpath -terse -no-tree -f $line`;
#		}
#		my @stdout_in_lines = split /\n/, $stdout;
#		foreach my $new_line (@stdout_in_lines){
#			if ($new_line =~ m/^total/) {
#				if ($new_line =~ m/0 errors/) {
#					print BOLD YELLOW $new_line, "\n";
#					next;
#				}
#				print BOLD RED $new_line, "\n";
#			}
#			else {
#				print "$new_line\n";
#			}
#		}
#	}
#}
exit 0;
