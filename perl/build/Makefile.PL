use ExtUtils::MakeMaker;

use Data::Dumper;


WriteMakefile(
    NAME            => 'drib',
    VERSION_FROM    => "bin/drib", # finds $VERSION
    PREREQ_PM       => {
			"File::Basename"	=> 0,
			"File::Find"		=> 0,
			"Digest::MD5"		=> 0,
			"Crypt::CBC"		=> 0,
			"JSON"				=> 0
		},
	INSTALLDIRS		=> 'vendor',
    PMLIBDIRS       => [qw(lib)],    
    EXE_FILES       => [qw(bin/drib)],
    AUTHOR          => 'Travis Kuhl <travis@drib.it>',
);


print Dumper(%Config); die;
