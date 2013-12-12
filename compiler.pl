use strict;
use warnings;

use Parser;

usage() unless (defined $ARGV[0]);

open(my $file, "<", $ARGV[0]) or die "Can't open $ARGV[0]: $!";

my $p = Parser->new();
$p->YYData->{DATA} = do {local $/, <$file>};

close($file);

$p->YYParse(YYlex => \&Parser::lex, YYerror => \&Parser::error);



sub usage {
	die "Usage: ...";
}
