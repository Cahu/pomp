package POMP::Sub;

use strict;
use warnings;


sub new {
	my ($class, $sub_name, $args, $code) = @_;
	return bless {
		name => $sub_name,
		args => $args,
		code => $code,
	}, $class;
}


sub print {
	my ($self, $out) = @_;

	if (!defined $out) {
		$out = \*STDOUT;
	}

	print $out "sub " . $self->{name} . " ";
	print $out $self->{code};
}

1;
