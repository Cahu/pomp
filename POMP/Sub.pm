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


sub gen_body {
	my $self = shift;
	return "sub " . $self->{name} . " " . $self->{code};
}


sub gen_call {
	my $self = shift;

	local $, = ", ";

	return '$_->enqueue(['
		. 'POMP::CALL, '
		. '__PACKAGE__ . "::' . $self->{name} . '"'
		. ', ' . "@{$self->{args}}"
		. ']) for (@POMP::POMP_QUEUES);'
	;
}

1;
