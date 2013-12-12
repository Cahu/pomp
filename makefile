all: Parser.pm

Parser.pm: Parser.yp
	yapp -o $@ $<

clean:
	rm -rf Parser.pm
