use strict;
use warnings;


#pomp_parallel begin
{
	print "toto\n";
}
#pomp_end

print "============\n";

within_sub();

sub within_sub {
	my $arg = shift;
	my (@arglist) = @_;

	#pomp_for begin
	for (1..10) {
		print "$_\n";
	}
	#pomp_end

	print "============\n";

	#pomp_for begin
	for (1..2) {
		print "$_\n";
	}
	#pomp_end
}
