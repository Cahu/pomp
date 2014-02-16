#!/bin/sh

for i in $(ls samples/); do
	echo "== Test: $i =========================";
	perl -Mblib compiler.pl samples/$i > out.pl
	perl -Mblib out.pl
	rm out.pl
done
