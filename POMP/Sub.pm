package POMP::Sub;

use strict;
use warnings;

use POMP::Indent;


sub new {
	my ($class, $sub_name, $code) = @_;
	return bless {
		name    => $sub_name,
		code    => $code,
		private => [],
		shared  => [],
	}, $class;
}


sub add_shared {
	my ($self, @shared) = @_;
	push @{$self->{shared}},  @shared;
}


sub add_private {
	my ($self, @private) = @_;
	push @{$self->{private}},  @private;
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
		. ']) for (@POMP::POMP_QUEUES);'
	;
}

1;
