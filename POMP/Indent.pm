package POMP::Indent;


sub indent {
	my ($code) = @_;
	$code =~ s/^/\t/gm;
	return $code;
}


sub reindent {
	my ($code) = @_;

	if ($code =~ /^(\t*)/) {
		$code =~ s/^$1//gme;
	}

	return $code;
}


sub get_level {
	my ($code) = @_;

	if ($code =~ /^(\t*)/) {
		return length $1;
	}

	return 0;
}


sub set_level {
	my ($code, $lvl) = @_;

	$lvl //= 1;

	my $indent = "\t" x $lvl;
	$code =~ s/^\t*/$indent/gm;

	return $code;
}

1;
