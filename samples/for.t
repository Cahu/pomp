use strict;
use warnings;

$" = ", ";

print "Number of threads used: $POMP::POMP_NUM_THREADS\n";

{
	my @list = 1..99;

	print "* test: print the (1 .. 99) list in parallel\n";

	#pomp_for
	for (@list) {
		print "$_\n";
	}
}

##pomp_for
#{
#	ok(0); # make sure this isn't executed
#}

{
	my @machin = 'a' .. 'c';

	print "* test: print the (@machin) list in parallel using a 'my' variable\n";

	#pomp_for
	foreach my $truc (@machin) {
		print "$truc\n";
	}
}

{
	my @bar = 'a' .. 'g';

	print "* test: print the (@bar) list in parallel\n";

	#pomp_for
	for (@bar) {
		print "$_\n";
	}
}
