package POMP::Reduction;

use strict;
use warnings;


sub init_for {
	my ($op) = @_;

	if    ($op eq "+") { return 0; }
	elsif ($op eq "-") { return 0; }
	elsif ($op eq "*") { return 1; }

	return undef;
}

1;

