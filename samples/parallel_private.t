use strict;
use warnings;

use Test::More tests => 6;

my $truc;
my @machin;
my %chose;

ok(!defined $truc  );
ok(! @machin);
ok(! %chose );

#pomp_parallel private($truc, @machin, %chose) shared() begin
{
	$truc = 10;

	@machin = ("machin", "chose", 1, 2);
	$machin[1] = "bidule";

	%chose = (1 => "truc", 7 => "bidule");
	$chose{3} = "mouton";
}
#pomp_end

ok(!defined $truc  );
ok(! @machin);
ok(! %chose );
