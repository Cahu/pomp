use strict;
use warnings;

use Test::More;

my $truc = 10;
my @machin = (1 .. 4);
my %chouette = ( toto => 'tutu' );

#pomp_parallel firstprivate($truc, @machin, %chouette) begin
{
	ok($truc == 10, "firstprivate scalar");
	is_deeply(\@machin, [1..4], "firstprivate list");
	is_deeply(\%chouette, { toto => 'tutu' }, "firstprivate hash");
}
#pomp_end

done_testing();