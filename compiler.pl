use strict;
use warnings;

use Parser;

usage() unless (defined $ARGV[0]);

open(my $file, "<", $ARGV[0]) or die "Can't open $ARGV[0]: $!";

my $p = Parser->new();
$p->YYData->{DATA} = do {local $/, <$file>};

close($file);


print <<'EOP';
### POMP Header --------------------
use POMP;
use threads::shared;
### --------------------------------

EOP

$p->YYParse(YYlex => \&Parser::lex, YYerror => \&Parser::error);

print <<'EOP';

### POMP GENERATED SUBS ------------

EOP

foreach my $s (@Parser::POMP_subs) {
	print $s->gen_body;
	print "\n";
}

print <<'EOP';
### --------------------------------
EOP


sub usage {
	die "Usage: ...";
}
