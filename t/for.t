use strict;
use warnings;


#pomp_for begin
for my $var (1..10) {
	print $_;
}
#pomp_end

#pomp_for begin
foreach my $truc (@machin) {
	print $truc;
}
#pomp_end

#pomp_for begin
for (@machin) {
	print $_;
}
#pomp_end

#pomp_for begin
for (my $i = 0; $i < 10; $i++) {
	print $i;
}
#pomp_end
