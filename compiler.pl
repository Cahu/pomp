use strict;
use warnings;

use Parser;
use Getopt::Long;

my $usage = <<EOU;
/path/to/perl $0 [options] <source file>

Options:
	-o <output file>     specify output file
	-h                   show this help
EOU


# Handle command line options
my $show_help;
my $output_file = "out.pl";
GetOptions(
	"o=s"  => \$output_file,
	"h"    => \$show_help,
	"help" => \$show_help,
);

# Check whether an input file was given
if ($show_help || !defined $ARGV[0]) {
	print $usage;
	exit;
}

# Open output file for writing
my $out;
if ($output_file eq "stdout") {
	open($out, ">&", STDOUT)
		or die "Can't dup STDOUT: $!";
} elsif ($output_file eq "stderr") {
	open($out, ">&", STDERR)
		or die "Can't dup STDERR $!";
} else {
	open($out, ">", $output_file)
		or die "Can't open $output_file: $!";
}

# Open input file
open(my $file, "<", $ARGV[0])
	or die "Can't open $ARGV[0]: $!";


# Slurp
my $p = Parser->new();
$p->YYData->{DATA} = do {
	local $/;
	<$file>;
};


close($file);


# header
print $out <<'EOP';
### POMP Header ---------------------------------------------
use POMP;
use threads::shared;          # for shared vars
use Storable qw(freeze thaw); # for copying firstprivate vars
### ---------------------------------------------------------

EOP


# modified user code
select $out; # write everything to the output file
$p->YYParse(YYlex => \&Parser::lex, YYerror => \&Parser::error);
select STDOUT;


# footer (generated subs)
print $out <<'EOP';

### POMP GENERATED SUBS -------------------------------------

EOP

foreach my $s (@Parser::POMP_subs) {
	print $out $s->gen_body;
	print $out "\n";
}

print $out <<'EOP';
### ---------------------------------------------------------
EOP

close($out);
