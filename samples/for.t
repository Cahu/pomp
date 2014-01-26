use strict;
use warnings;


my @truc;
my @list = 1..10;
#pomp_for shared(@truc) begin
for (@list) {
	$truc[1] = 10;
	print $_ . "\n";
}
#pomp_end

##pomp_for begin
#{
#	print "truc";
#}
##pomp_end

##pomp_for begin
#foreach my $truc (@machin) {
#	print $truc;
#}
##pomp_end
#
##pomp_for begin
#for (@machin) {
#	print $_;
#}
##pomp_end
