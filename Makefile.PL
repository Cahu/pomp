use 5.014;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POMP',
    VERSION_FROM      => 'lib/POMP.pm', # finds $VERSION
    PREREQ_PM         => {
	 	'Parse::Yapp'    => 0,
		'Text::Balanced' => 0,
	},
);

sub MY::postamble {
    join("\n",
		"all::",
		"\tyapp Parser.yp",
		"clean::",
		"\trm Parser.pm",
    );
}
