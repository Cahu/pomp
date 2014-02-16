use strict;
use warnings;

print "Number of threads used: $POMP::POMP_NUM_THREADS\n";
print "* test: all threads print the same thing\n";

#pomp_parallel begin
{
	print "toto\n";
}
#pomp_end

