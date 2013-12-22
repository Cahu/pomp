package POMP::Clause;

use POMP::Indent;


sub gen_if {
	my ($cond, $code) = @_;
	return "if ($cond) { " .  $code . " }\n";
}

1;
