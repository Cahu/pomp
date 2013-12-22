package POMP::Sub;

use strict;
use warnings;

use POMP::Indent;


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
	return "sub " . $self->{name} . " {\n"
	     . POMP::Indent::indent($self->{code}) . "\n"
	     . "}\n";
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
