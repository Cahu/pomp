package POMP::Indent;

sub reindent {
	my ($code) = @_;

	if ($code =~ /^(\t*)/) {
		$code =~ s/^$1//gme;
	}

	return $code;
}

1;
