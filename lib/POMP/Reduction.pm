package POMP::Reduction;

use strict;
use warnings;

sub new {
	my $class = shift;
	my ($init_value, $sub) = @_;

	return bless {
		init => $init_value,
		sub  => $sub,
	}
}


sub init {
	my $self = shift;
	return $self->{init};
}


sub apply {
	my $self = shift;
	return $self->{sub}->(@_);
}

1;

__END__

=pod

=head1 Methods

=over 4

=item C<new($init_value, $sub)>

The scalar passed in C<$init_value> is the value to use to initialize the accumulator.

The subroutine passed via C<$sub> shall take two arguments. The first one is the
accumulator, the second one is the name of a reference to a list of values to be
prosessed and adeded to the accumulator.

=item C<init>

Returns the init value of the accumulator.

=item C<apply>

Output the generated code.

=back

=cut

