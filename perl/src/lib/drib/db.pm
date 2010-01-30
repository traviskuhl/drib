#
#  drib::db
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package drib::db;

my $VERSION = "0.0.1";

# external
use JSON;
use POSIX;
use Data::Dumper;

# drib
use drib::utils;

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

sub all {
    my ($self,$ns) = @_;

    # no namespace
    unless ( $ns ) { 
        $ns = "default";
    }
    
    # return all 
    return $self->{content}->{$ns};

}

sub get {

	my ($self,$var,$ns) = @_;

    # no namespace
    unless ( $ns ) { 
        $ns = "default";
    }    

	if ( exists $self->{content}->{$ns}->{$var} )  {
		return $self->{content}->{$ns}->{$var};
	}
	else {
		return 0;
	}

}

sub set {

	my ($self,$var,$val,$ns) = @_;

    # no namespace
    unless ( $ns ) { 
        $ns = "default";
    }    
    
    # does it exist
    unless ( exists $self->{content}->{$ns} ) {
        $self->{content}->{$ns} = {};
    }

	# set
    return $self->{content}->{$ns}->{$var} = $val;

}


sub unset {

    # get stuff
    my ($self,$key,$ns) = @_;

    # no namespace
    unless ( $ns ) { 
        $ns = "default";
    }    

    # delete it
    delete $self->{content}->{$ns}->{$key};
    
}


sub add {

    my ($self,$var,$val,$ns) = @_;
    
    # no namespace
    unless ( $ns ) { 
        $ns = "default";
    }        
    
    # eixst
    unless ( exists $self->{content}->{$ns} ) {
        $self->{content}->{$ns} = {};
    }

    # default
    unless ( exists $self->{content}->{$ns}->{$val} ) {
        $self->{content}->{$ns}->{$val} = ();
    }    
    
    my @a = @{$self->{content}->{$ns}->{$var}};
    
    # push me on
    unless ( in_array(\@a,$val)) {
        push(@a,$val);
    }
    
    # save it 
    $self->{content}->{$ns}->{$var} = \@a;

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
	$file = $self->{var}.'/'.$self->{db}.'.json';

    # save
	open(_FH,">".$file);
	print _FH to_json($content);
	close(_FH);

}

