package utils;

use Data::Dumper;
use JSON;
use base qw(Exporter);


our @EXPORT = qw(
	trim
	file_get
	file_put
	fail
	msg
	verbose
	rand_str
	force_root
);

sub trim {
	my $string = shift;
	$string =~ s/\/$//;
	return $string;	
}

sub file_get {
	
	my ($file) = @_;

	open(FH,$file);
	my @f = <FH>;
	close(FH);
	
	return join("",@f);

}

sub file_put {
	
	my ($file,$content) = @_;

	open(FH,">".$file);
	print FH $content;
	close(FH);

}

sub fail {
	my $msg = shift;
	print $msg ."\n";
	exit;
}

sub msg {
	my $msg = shift;
	print $msg ."\n";
}

sub verbose {
	my $msg = shift;
	print $msg ."\n";
}

sub rand_str {
	my $length_of_randomstring=shift;# the length of 
			 # the random string to generate

	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		# rand @chars will generate a random 
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

sub force_root {
    
    if ( $> != 0 ) {
        fail("Must run install commands as 'root'.");
    }

}
