package POMP::Sub;

use strict;
use warnings;

use Template;

use POMP::Indent;
use POMP::Reduction;


sub new {
	my ($class, $sub_name, $code) = @_;
	return bless {
		name         => "pomp_" . $sub_name,
		code         => $code,
		shared       => {},
		private      => {},
		firstprivate => {},
		reduction    => {},
		foreach      => undef,
	}, $class;
}


sub add_shared {
	my ($self, @shared) = @_;
	for (@shared) {
		$self->{shared}->{$_} = 1;
		delete $self->{private     }->{$_};
		delete $self->{reduction   }->{$_};
		delete $self->{firstprivate}->{$_};
	}
}


sub add_reduction {
	my $self = shift;
	my ($var_expr, $reduction) = @_;

	# add var, the initial value and the oprator to the reduction hash
	unless (exists $self->{shared}->{$_}) {
		$self->{reduction}->{$var_expr} = $reduction;
		delete $self->{private     }->{$_};
		delete $self->{firstprivate}->{$_};
	}
}


sub add_firstprivate {
	my ($self, @firstprivate) = @_;
	for (@firstprivate) {
		unless (
			   exists $self->{shared}->{$_}
			|| exists $self->{reduction}->{$_}
		) {
			$self->{firstprivate}->{$_} = 1;
			delete $self->{private}->{$_};
		}
	}
}


sub add_private {
	my ($self, @private) = @_;
	for (@private) {
		unless (
			   exists $self->{shared}->{$_}
			|| exists $self->{reduction}->{$_}
			|| exists $self->{firstprivate}->{$_}
		) {
			$self->{private}->{$_} = 1;
		}
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
	$private_vars .= "my $_;\n" foreach (keys %{$self->{private}});

	my $shared_vars = "";
	foreach my $shared (keys %{$self->{shared}}) {
		# Shared variables are passed by reference (result of shared_clone from
		# threads::shared). We must substitute all occurences of these variables
		# with the corresponding dereference instruction.
		my $substitute = _substitute_with_refs($shared, \($self->{code}));
		$shared_vars .= "my \$$substitute = shift;\n";
	}

	my $reduction_vars = "";
	while (my ($var_name, $reduction) = each %{$self->{reduction}}) {
		my $initial_value = $reduction->init;
		# create local version of the reduced vars and init with initial value
		$reduction_vars .= "my $var_name = $initial_value;\n";
	}

	my $firstprivate_vars = "";
	foreach my $firstprivate (keys %{$self->{firstprivate}}) {
		# Make a local copy with Storable::thaw
		my $substitute = _substitute_with_refs($firstprivate, \($self->{code}));
		$firstprivate_vars .= "my \$$substitute = thaw(shift);\n";
	}

	my $body = "";

	# private and shared local variables
	$body .= $private_vars . $reduction_vars . $firstprivate_vars . $shared_vars;

	# foreach loops
	if ($self->{foreach}) {
		my $var_name = $self->{foreach}->{var_name};

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

	$body .= "POMP::ENQUEUE(freeze(\\$_));\n" for (keys %{$self->{reduction}});

	$body .= "POMP::BARRIER();\n"; # synchronize threads

	return "sub " . $self->{name} . " {\n"
		. POMP::Indent::indent($body)
		. "}\n";
}


sub gen_call {
	my $self = shift;

	# generate shared clones
	my @shared_vars;
	for my $shared (keys %{$self->{shared}}) {
		my ($sigil, $name) = ($shared =~ /^([\$@%])(.*)/);

		push @shared_vars, {
			sigil      => $sigil,
			name       => $shared,
			clone_name => '$' . $self->{name} . "_$name",
		};
	}

	# generate reductions
	my @reductions;
	while (my ($var_name, $reduction) = each %{ $self->{reduction} }) {
		push @reductions, {
			var_name  => $var_name,
			reduction => $reduction,
		};
	}

	my @firstprivate_vars = keys %{ $self->{firstprivate} };

	my $tt = Template->new({
		PRE_CHOMP  => 1,
		POST_CHOMP => 1,
	}) or die "$Template::ERROR\n";

	my $vars = {
		func_name         => $self->{name},
		shared_vars       => \@shared_vars,
		firstprivate_vars => \@firstprivate_vars,
		reductions        => \@reductions,
		foreach           => $self->{foreach},
	};

	my $output = '';
	$tt->process('templates/call.tt', $vars, \$output)
		or die $tt->error . "\n";

	return $output;
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
