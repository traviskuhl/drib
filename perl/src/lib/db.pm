package drib::db;

my $VERSION = "0.0.1";

# need json
use JSON;
use POSIX;
use utils;
use Data::Dumper;

sub new {

	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	
	# bless me
	bless $self, $class;

	# get 
	my $db = shift;
	my $var = shift;	

	# load our dbs
	$self->{var} = $var;
	$self->{db} = $db;

	# load it 
	$self->load();
	
	# return
	return $self;

}
sub get {

	my ($self,$var) = @_;

	if ( exists $self->{content}->{$var} )  {
		return $self->{content}->{$var};
	}
	else {
		return 0;
	}

}

sub set {

	my ($self,$var,$val) = @_;

	# set
	return $self->{content}->{$var} = $val;

}


sub load {
	
	my $self = shift;
	
	# open the file
	$file = trim($self->{var}).'/'.trim($self->{db}).'.json';
	
	# doesn't exist
	if ( -e $file ) {
		$self->{content} = from_json(file_get( $file ));
	}
	else {
		$self->{content} = {};
	}

}

sub save {

	my ($self,$content) = @_;

	# no content
	if ( !$content ) {
		$content = $self->{content};
	}

	# open the file
	$file = $self->{var}.'/'.$self->{db};

	file_put($file,$content);

}


