use strict;
use warnings;

use Test::More;

my $var = 5;

#pomp_for reduction(+:$var)
for (1 .. 100) {
	$var += 1;
}

cmp_ok($var, "==", 105, "'+' operator reduction");

#pomp_for reduction(+:$var)
for (1 .. 105) {
	$var -= 1;
}

cmp_ok($var, "==", 0, "'-' operator reduction");


my $pow = 1;

#pomp_for reduction(*:$pow)
for (1 .. 6) {
	$pow *= 2;
}

cmp_ok($pow, "==", 64, "'*' operator reduction"); # 2^6


my @list = ();

#pomp_for reduction(push:@list)
for ('a' .. 'z') {
	push @list, $_;
}

is_deeply([sort @list], ['a' .. 'z'], "push reduction");

done_testing();
