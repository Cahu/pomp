use strict;
use warnings;

$" = ", ";

print "Number of threads used: $POMP::POMP_NUM_THREADS\n";

{
	my @list = 1..2;

	print "* test: print the (@list) list in parallel\n";

	#pomp_for begin
	for (@list) {
		print "$_\n";
	}
}

##pomp_for begin
#{
#	print "truc";
#}

{
	my @machin = 'a' .. 'c';

	print "* test: print the (@machin) list in parallel using a 'my' variable\n";

	#pomp_for begin
	foreach my $truc (@machin) {
		print "$truc\n";
	}
}

{
	my @bar = 'a' .. 'g';

	print "* test: print the (@bar) list in parallel\n";

	#pomp_for begin
	for (@bar) {
		print "$_\n";
	}
}
