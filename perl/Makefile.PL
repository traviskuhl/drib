use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "drib",
    VERSION_FROM    => "src/bin/drib",
    PREREQ_PM       => {
			"File::Basename"	=> 0,
			"File::Find"		=> 0,
			"Digest::MD5"		=> 0,
			"Crypt::CBC"		=> "2.30",
			"JSON"				=> "2.17",
			"HTTP::Request"		=> 0
		},
	PREREQ_FATAL	=> 1,
	INSTALLDIRS		=> 'vendor',
	PMLIBDIRS       => [qw(src/lib)],
    EXE_FILES       => [qw(src/bin/drib)],
    AUTHOR          => 'Travis Kuhl <travis@drib.it>',
);