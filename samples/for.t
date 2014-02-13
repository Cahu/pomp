use strict;
use warnings;


my @truc;
my @list = 1..10;
#pomp_for shared(@truc) begin
for (@list) {
	$truc[1] = 10;
	print $_ . "\n"
	;
}
#pomp_end

##pomp_for begin
#{
#	print "truc";
#}
##pomp_end

my @machin = 'a' .. 'c';

#pomp_for begin
foreach my $truc (@machin) {
	print "$truc\n";
}
#pomp_end

my @bar = 'a' .. 'z';

#pomp_for begin
for (@bar) {
	print "$_\n";
}
#pomp_end


#pomp_for begin
for (1..10) {
	print "$_\n";
}
#pomp_end

#pomp_for begin
for my $stuff (1..5) {
	print "$stuff\n";
}
#pomp_end
