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
		reduction    => [],
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


sub add_reduction {
	my $self = shift;
	my ($op, @varlist) = @_;

	# add var, the initial value and the oprator to the reduction array

	if ($op eq "+") {
		push @{$self->{reduction}}, map { [$_, 0, $op] } @varlist;
	}

	elsif ($op eq "-") {
		push @{$self->{reduction}}, map { [$_, 0, $op] } @varlist;
	}

	elsif ($op eq "*") {
		push @{$self->{reduction}}, map { [$_, 1, $op] } @varlist;
	}
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
	$private_vars .= "my $_;\n" foreach (@{$self->{private}});

	my $shared_vars = "";
	foreach my $shared (@{$self->{shared}}) {
		# Shared variables are passed by reference (result of shared_clone from
		# threads::shared). We must substitute all occurences of these variables
		# with the corresponding dereference instruction.
		my $substitute = _substitute_with_refs($shared, \($self->{code}));
		$shared_vars .= "my \$$substitute = shift;\n";
	}

	my $reduction_vars = "";
	foreach my $reduc (@{$self->{reduction}}) {
		# create local version of the reduced vars and init with initial value
		$reduction_vars .= "my $reduc->[0] = $reduc->[1];\n";
	}

	my $firstprivate_vars = "";
	foreach my $firstprivate (@{$self->{firstprivate}}) {
		# Make a local copy with Storable::thaw
		my $substitute = _substitute_with_refs($firstprivate, \($self->{code}));
		$firstprivate_vars .= "my \$$substitute = thaw(shift);\n";
	}

	my $body = "";

	# private and shared local variables
	$body .= $private_vars . $reduction_vars . $firstprivate_vars . $shared_vars;

	# foreach loops
	if ($self->{foreach}) {
		my $var_name  = $self->{foreach}->{var_name};
		my $list_expr = '@pomp_iteration_list';

		# remaining arguments are to be given to the foreach
		$body .= _gen_for(
			$var_name,
			'POMP::GET_SHARE(@_)',
			$self->{code}
		);
	}

	else {
		$body .= $self->{code};
	}

	$body .= "POMP::ENQUEUE(freeze(\\$_->[0]));\n" for (@{$self->{reduction}});

	$body .= "POMP::BARRIER();\n"; # synchronize threads

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

	# generate arguments for firstprivate and cloned variables.
	# pass frozen versions of these variables to perform a deep copy which will
	# be used to reconstitute the data structure localy with thaw() by each
	# thread.
	$args_str .= join (", ",
		(map { "freeze(\\$_)" } @{$self->{firstprivate}}),
		@clones,
	);

	# last argument is the index list to be given to foreach.
	# force list context by adding parenthesis.
	if ($self->{foreach}) {
		$args_str .= ", " if (length $args_str > 0);
		$args_str .= "($self->{foreach}->{list_expr})";
	}

	# terminate the enqueue instruction
	$call .= ", $args_str" if ($args_str);
	$call .= ']) for (@POMP::POMP_IN_QUEUES);' . "\n";

	# make the main thread call the same function with the same arguments
	$call .= $self->{name} . "($args_str);\n";

	# copy back values from shared clones into original vars
	for my $shared (@{$self->{shared}}) {
		my ($sigil, $name) = ($shared =~ /^([\$@%])(.*)/);
		my $clone_name = "\$" . $self->{name} . "_$name";
		$call .= "$shared = $sigil\{$clone_name\};";
	}

	# handle reductions
	foreach my $reduc (@{$self->{reduction}}) {
		my $op  = $reduc->[2];
		my $var = $reduc->[0];
		$call .= "$var = $var $op \${thaw(\$_->dequeue)} for(\@POMP::POMP_OUT_QUEUES);\n";
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

sub _substitute_with_refs {
	my ($var, $code_ref) = @_;

	my ($sigil, $barename) = ($var =~ /^([\$@%])(.*)/);
	my $substitute;

	if ($sigil eq '@') {
		$substitute = "pomp_array_" . $barename;
		$$code_ref =~ s/\@$barename/\@\{\$$substitute\}/g;
		$$code_ref =~ s/\$$barename\s*\[/\$$substitute->\[/g;
	}

	elsif ($sigil eq '%') {
		$substitute = "pomp_hash_" . $barename;
		$$code_ref =~ s/\%$barename/\%\{\$$substitute\}/g;
		$$code_ref =~ s/\$$barename\s*\{/\$$substitute->\{/g;
	}

	elsif ($sigil eq '$') {
		$substitute = "pomp_scalar_" . $barename;
		$$code_ref =~ s/\$$barename/\$\$$substitute/g;
	}

	return $substitute;
}

1;
