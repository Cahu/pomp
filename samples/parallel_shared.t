use strict;
use warnings;

use Test::More;

my $truc;
my @machin;
my %chose;

ok(!defined $truc  );
ok(! @machin);
ok(! %chose );


#pomp_parallel shared($truc, @machin, %chose)
{
	$truc = 10;

	@machin = ("machin", "chose", 1, 2);
	$machin[1] = "bidule";

	%chose = (1 => "truc", 7 => "bidule");
	$chose{3} = "mouton";
}

ok($truc == 10);

is_deeply(
	\@machin, 
	["machin", "bidule", 1, 2],
);

is_deeply(
	\%chose,
	{ 1 => "truc",
	  3 => "mouton",
	  7 => "bidule",
	}
);

done_testing();
