package POMP::Clause;

sub gen_if {
	my ($cond, $code) = @_;
	return "if ($cond) {\n" .  $code . "\n}\n";
}

1;
