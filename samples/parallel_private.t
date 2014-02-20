use strict;
use warnings;

use Test::More;

my $truc = 20;
my @machin = ('a' .. 'z');
my %chose = ( toto => 'tutu' );


#pomp_parallel private($truc, @machin, %chose) shared()
{
	$truc = 10;

	@machin = ("machin", "chose", 1, 2);
	$machin[1] = "bidule";

	%chose = (1 => "truc", 7 => "bidule");
	$chose{3} = "mouton";
}

ok($truc == 20, "scalar not modified");
is_deeply(\@machin, ['a' .. 'z'], "list still the same");
is_deeply(\%chose, { toto => 'tutu' }, "hash still the same");

done_testing();
