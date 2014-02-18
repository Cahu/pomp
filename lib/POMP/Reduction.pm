package POMP::Reduction;

use strict;
use warnings;

sub new {
	my $class = shift;
	my ($init_value, $sub) = @_;

	return bless {
		init => $init_value,
		sub  => $sub,
	}
}


sub init {
	my $self = shift;
	return $self->{init};
}


sub apply {
	my $self = shift;
	return $self->{sub}->(@_);
}

1;

