use strict;
use warnings;

#pomp_for if() shared() begin
{
	print "toto";
}
#pomp_end

sub foo {
	$_[0] + 1;
}

#pomp_parallel begin
{
	map { print "$_\n" } (1 .. 10);
}
	#pomp_end

#pomp_truc bazar truc begin
{
	print "Yo!\n";
}
#pomp_end
