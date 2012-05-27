# drib-util

package drib::util;

# stuff to use
use File::Basename;

# new
sub new {

    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};

    # bless me
    bless $self, $class; 

    # drib
    $self->{drib} = shift;
    
    # return
    return $self;

}

##
## @brief drib shortcut
##
sub drib {
	return shift->{drib};
}

##
## @brief dump shoftcut
##
sub dump {
	return shift->drib->dump(shift);
}

##
## @brief parse a file
##
sub parseFile {
	my ($self, $file, $vars) = @_;

	# get our ext
	my ($a, $b, $ext) = fileparse(lc($file), qr/[^.]*/);

	# parser
	my $parser = 0;

	# do we already have them?
	foreach my $class ($self->drib->parsers) {

		# get ext
		my $e = $class."::ext";

		# get the ext
		if (lc(&$e()) eq $ext) {
			$parser = $class;
		}

	}	

	# no parser
	unless ($parser) {
		return 0;
	}

	# parser
	my $p = $parser."::parse";

	# parser it 
	return &$p($self->drib, $file, $vars);

}

##
## @brief figure parser by file name
##
sub getParsableFiles {
	my $self = shift;
	my $dir = shift;

	# files
	my @files = ();

	# do we already have them?
	foreach my $class ($self->drib->parsers) {

		# get ext
		my $e = $class."::ext";

		# get the ext
		push(@files, glob($dir."/*.".&$e()));

	}

	return \@files;

}

return 1;