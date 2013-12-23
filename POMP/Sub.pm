package POMP::Sub;

use strict;
use warnings;

use POMP::Indent;


sub new {
	my ($class, $sub_name, $args, $code) = @_;
	return bless {
		name    => $sub_name,
		args    => $args,
		code    => $code,
		private => [],
		shared  => [],
	}, $class;
}


sub add_privates {
	my ($self, @privates) = @_;
	push @{$self->{private}},  @privates;
}


sub gen_body {
	my $self = shift;

	my $private_vars = "";
	$private_vars   .= "my $_;\n" foreach (@{$self->{private}});

	return "sub " . $self->{name} . " {\n"
	     . POMP::Indent::indent($private_vars . $self->{code}) . "\n"
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
