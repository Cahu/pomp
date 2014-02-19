#!/bin/sh

for i in $(ls samples/); do
	echo "== Test: $i =========================";
	perl -Mblib compiler.pl -o out.pl samples/$i
	perl -Mblib out.pl
	rm out.pl
done
