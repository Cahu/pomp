package POMP::Sub;

use strict;
use warnings;

use POMP::Indent;


sub new {
	my ($class, $sub_name, $code) = @_;
	return bless {
		name         => "pomp_" . $sub_name,
		code         => $code,
		shared       => [],
		private      => [],
		firstprivate => [],
		foreach      => undef,
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


sub add_firstprivate {
	my ($self, @firstprivate) = @_;
	push @{$self->{firstprivate}},  @firstprivate;
}


sub add_foreach {
	my ($self, $var_name, $list_expr) = @_;
	$self->{foreach} = {
		var_name  => $var_name,
		list_expr => $list_expr,
	};
}


sub gen_body {
	my $self = shift;

	my $private_vars = "";
	my $firstprivate_vars = "";
	$private_vars      .= "my $_;\n"         foreach (@{$self->{private}     });
	$firstprivate_vars .= "my $_ = shift;\n" foreach (@{$self->{firstprivate}});

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

	my $body = "";

	# private and shared local variables
	$body .= $private_vars . $firstprivate_vars . $shared_vars;

	# foreach loops
	if ($self->{foreach}) {
		my $var_name  = $self->{foreach}->{var_name};
		my $list_expr = '@pomp_iteration_list';

		# last argument is the foreach list
		$body .= "my $list_expr = \@_;\n";

		my $start_var = "\$POMP_FOREACH_START";
		my $end_var   = "\$POMP_FOREACH_END";

		# strategy = distribute the same amount of indices to each thread
		$body .= "return if (threads->tid()+1 > $list_expr);\n";
		$body .= "my $start_var;\n";
		$body .= "my $end_var;\n";
		$body .= _gen_if_else(
			"\$POMP::POMP_NUM_THREADS >= $list_expr",

			  "$start_var = threads->tid();\n"
			. "$end_var   = threads->tid();\n",

			  "$start_var = int("
			. "threads->tid()*$list_expr" . "/" . "\$POMP::POMP_NUM_THREADS"
			. ");\n"
			. "$end_var   = int("
			. "(1+threads->tid())*$list_expr" . "/" . "\$POMP::POMP_NUM_THREADS-1"
			. ");\n"
		);

		# for my $var (@list) { ... }
		$body .= _gen_for(
			$var_name,
			"$list_expr\[$start_var .. $end_var\]",
			$self->{code}
		);
	}

	else {
		$body .= $self->{code};
	}

	return "sub " . $self->{name} . " {\n"
		. POMP::Indent::indent($body)
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

	my $args_str = "";

	# generate arguments for firstprivate and cloned variables
	$args_str .= join (", ",
		@{$self->{firstprivate}},
		@clones,
	);

	# last argument is the foreach list
	if ($self->{foreach}) {
		$args_str .= ", " if (length $args_str > 0);
		$args_str .= "($self->{foreach}->{list_expr})";
	}

	# terminate the enqueue instruction
	$call .= ", $args_str" if ($args_str);
	$call .= ']) for (@POMP::POMP_IN_QUEUES);' . "\n";

	# make the main thread call the same function
	$call .= '__PACKAGE__ . ::' . $self->{name} . "($args_str);\n";

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

sub _gen_if {
	my ($cond_str, $body) = @_;

	return "if ($cond_str) {\n"
		. POMP::Indent::indent($body)
		. "}\n";
}

sub _gen_if_else {
	my ($cond_str, $body1, $body2) = @_;

	return "if ($cond_str) {\n"
		. POMP::Indent::indent($body1)
		. "} else {\n"
		. POMP::Indent::indent($body2)
		. "}\n";
}

sub _gen_for {
	my ($var_expr, $list_expr, $body) = @_;

	return "for" . ($var_expr ? " my $var_expr " : " ") . "($list_expr) {\n"
		. POMP::Indent::indent($body)
		. "}\n";
}

sub _gen_while {
	my ($cond_str, $body) = @_;

	return "while ($cond_str) {\n"
		. POMP::Indent::indent($body)
		. "}\n";
}

1;
