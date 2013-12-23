use strict;
use warnings;

my $truc = 1;

my @bidule = ("lalalala", "lolololo");
my @machin = ("hey", "yo!");
my %toto   = (truc => "chouette", machin => "truc");
my $tutu   = "this is tutu";

#pomp_for
# if($truc)
# shared(@machin, %toto, $tutu)
# private($truc, @bidule)
# begin
for (1..10) {
	$truc = 10;
	print "toto";
	push @machin, "$truc";
	$machin[3] = "$tutu";
	$toto{truc} = $truc;
}
#pomp_end

sub foo {
	#pomp_parallel
	# if($truc)
	# begin
	{
		for (1..10) {
			print "tata $_\n";
		}
		print "tutu\n";
	}
	#pomp_end
	return $_[0] + 1;
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

foo(2);
