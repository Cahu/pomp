use strict;
use warnings;

use Test::More;

my $var = 5;

#pomp_for reduction(+:$var) begin
for (1 .. 100) {
	$var += 1;
}
#pomp_end

cmp_ok($var, "==", 105);

#pomp_for reduction(+:$var) begin
for (1 .. 105) {
	$var -= 1;
}
#pomp_end

cmp_ok($var, "==", 0);


my $pow = 1;

#pomp_for reduction(*:$pow) begin
for (1 .. 6) {
	$pow *= 2;
}
#pomp_end

cmp_ok($pow, "==", 64); # 2^6


my @list = ();

#pomp_for reduction(push:@list) begin
for ('a' .. 'z') {
	push @list, $_;
}
#pomp_end

is_deeply([sort @list], ['a' .. 'z']);

done_testing();
