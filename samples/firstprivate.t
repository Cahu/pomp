use strict;
use warnings;

use Test::More;

my $truc = 10;
my @machin = (1 .. 4);
my %chouette = ( toto => 'tutu' );

#pomp_parallel firstprivate($truc, @machin, %chouette)
{
	ok($truc == 10, "firstprivate scalar init");
	is_deeply(\@machin, [1..4], "firstprivate list init");
	is_deeply(\%chouette, { toto => 'tutu' }, "firstprivate hash init");

	$truc = 20;
	ok($truc == 20, "firstprivate scalar modification");

	@machin = ('a' .. 'z');
	is_deeply(\@machin, ['a' .. 'z'], "firstprivate list modification");

	%chouette = ( titi => 'tata' );
	is_deeply(\%chouette, { titi => 'tata' }, "firstprivate hash modification");
}

ok($truc == 10, "firstprivate scalar unchanged");
is_deeply(\@machin, [1..4], "firstprivate list unchanged");
is_deeply(\%chouette, { toto => 'tutu' }, "firstprivate hash unchanged");

done_testing();
