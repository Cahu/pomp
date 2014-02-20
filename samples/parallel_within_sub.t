use strict;
use warnings;

print "* test: try some #pomp_* instructions within a sub.\n";

within_sub("toto");

sub within_sub {
	my $arg = shift;
	my (@arglist) = @_;

	#pomp_for firstprivate($arg)
	for (1..10) {
		print "$arg: $_\n";
	}
}
