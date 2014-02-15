use strict;
use warnings;

use Test::More;

my @A = (
	[7, 0,  4, 1],
	[1, 6,  2,-1],
	[3,-5, 10, 4],
	[4, 6, -9, 3]
);


my @A_square = (
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
);

my @answer = (
	[65, -14,  59,  26],
	[15,  20,  45,   0],
	[62, -56,  66,  60],
	[19,  99, -89, -29]
);

#pomp_for shared(@A_square) firstprivate(@A) begin
for my $i (0 .. 3) {
	for my $j (0 .. 3) {
		for my $k (0 .. 3) {
			$A_square[$i][$j] += $A[$i][$k] * $A[$k][$j];
		}
	}
}
#pomp_end

for my $i (0 .. 3) {
	for my $j (0 .. 3) {
		print "\t$A_square[$i][$j]";
	}
	print "\n";
}

is_deeply(\@A_square, \@answer);

done_testing();
