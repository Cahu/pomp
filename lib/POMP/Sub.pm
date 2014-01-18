package POMP::Sub;

use strict;
use warnings;

use POMP::Indent;


sub new {
	my ($class, $sub_name, $code) = @_;
	return bless {
		name    => "pomp_" . $sub_name,
		code    => $code,
		private => [],
		shared  => [],
		loop    => undef,
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


sub add_loop {
	my ($self, $expr) = @_;
	${$self->{loop}} = $expr;
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
		my ($barename) = ($shared =~ /^[\$@%](.*)/);
		my $substitute = $self->{name} . "_" . $barename;

		if ($shared =~ /^@/) {
			$self->{code} =~ s/\@$barename/\@\{\$$substitute\}/;
			$self->{code} =~ s/\$$barename\s*\[/\$$substitute->\[/;
		}

		elsif ($shared =~ /^%/) {
			$self->{code} =~ s/\%$barename/\%\{\$$substitute\}/;
			$self->{code} =~ s/\$$barename\s*\{/\$$substitute->\{/;
		}

		elsif ($shared =~ /^\$/) {
			$self->{code} =~ s/\$$barename/\$\$$substitute/;
		}

		else {
			warn "Couldn't generate variable for '$shared'";
			next;
		}

		$shared_vars .= "my \$$substitute = shift;\n";
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

	my @clones;
	my $call = "";

	# generate shared clones
	for my $shared (@{$self->{shared}}) {
		my ($sigil, $name) = ($shared =~ /^([\$@%])(.*)/);
		my $clone_name = "\$" . $self->{name} . "_$name";
		$call .= "my $clone_name = shared_clone(\\$shared);\n";
		push @clones, $clone_name;
	}

	# start the enqueue instruction
	$call .= '$_->enqueue(['
		. 'POMP::CALL, '
		. '__PACKAGE__ . "::' . $self->{name} . '"'
	;

	# Add subset of loop values as the first argument
	# TODO

	# Add clones as argument
	$call .= ", $_" for (@clones);

	# terminate the enqueue instruction
	$call .= ']) for (@POMP::POMP_IN_QUEUES);' . "\n";

	# Synchronize
	$call .= '$_->dequeue for (@POMP::POMP_OUT_QUEUES);';

	# copy back values
	for my $shared (@{$self->{shared}}) {
		my ($sigil, $name) = ($shared =~ /^([\$@%])(.*)/);
		my $clone_name = "\$" . $self->{name} . "_$name";
		$call .= "\n$shared = $sigil\{$clone_name\};";
	}

	return $call;
}

1;
