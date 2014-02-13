use strict;
use warnings;

use Test::More;

my $truc = 10;

#pomp_parallel firstprivate($truc) begin
{
	ok($truc == 10);
}
#pomp_end

done_testing();
