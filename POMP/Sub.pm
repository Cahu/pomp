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

	my $shared_vars = "";
	foreach my $shared (@{$self->{shared}}) {
		# Shared variables are passed by reference (result of shared_clone from
		# threads::shared). We must substitute all occurences of these variables
		# with the corresponding dereference instruction.
		my $barename;
		if ($shared =~ /^@(.*)/) {
			$barename = $1;
			$self->{code} =~ s/\@$barename/\@\{\$$barename\}/;
			$self->{code} =~ s/\$$barename\s*\[/\$$barename->\[/;
		}

		elsif ($shared =~ /^%(.*)/) {
			$barename = $1;
			$self->{code} =~ s/\%$barename/\%\{\$$barename\}/;
			$self->{code} =~ s/\$$barename\s*\{/\$$barename->\{/;
		}

		elsif ($shared =~ /^\$(.*)/) {
			$barename = $1;
			$self->{code} =~ s/\$$barename/\$\$$barename/;
		}

		else {
			warn "Couldn't generate variable for '$shared'";
			next;
		}

		$shared_vars .= "my \$$barename = shift;\n";
	}

	return "sub " . $self->{name} . " {\n"
	     . POMP::Indent::indent(
			   $private_vars
			 . $shared_vars
			 . $self->{code}
		 )
		 . "\n"
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
