# drib::db;

package drib::db;

# external
use JSON;
use POSIX;
use Data::Dumper;

sub new {

    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};

    # bless me
    bless $self, $class; 

    # get 
    $self->{var} = shift;
    $self->{db} = shift;
    
    # loaded
    $self->{loaded} = 0;
    $self->{changes} = 0;

    # load it 
    $self->load();
    
    # return
    return $self;

}

# save on destory
sub DESTROY {

    # get yourself
    my $self = shift;
    
    # make sure it was loaded ok
    # before we save. don't want to
    # save a bad version
    if ( $self->{loaded} == 1 ) {    
        $self->save();
    }
    
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

    # changes
    $self->{changes} = 1;
    
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
    
    # changes
    $self->{changes} = 1;    

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
    
    # changes
    $self->{changes} = 1;    
    
    # save it 
    $self->{content}->{$ns}->{$var} = \@a;

}

sub load {
    
    my $self = shift;
    
    # open the file
    $d = $self->{var};
    $f = $self->{db}.'.json';
    $file = $d.$f;
    
    # backups 
    my $bk = $self->{var}.'backups/';
    
        # check for backup folder
        unless ( -e $bk ) {
            `mkdir $bk`;
        }    
        
    # doesn't exist
    if ( -e $file ) {
                
        # set 
        eval {
                        
            # self
            $self->{content} = from_json($self->file_get( $file ));
            
            # loaded
            if ( ref $self->{content} eq "HASH" ) {
            
                # loaded
                $self->{loaded} = 1;
                
                # it's ok to backup what we have
                `cp $file $bk$f`;
                
            }
            
        }
                
    }
    else {
    
        # loaded
        $self->{loaded} = 1;    
    
        # no content
        $self->{content} = {};
                
    }

}

sub save {

    my ($self,$content) = @_;

    # no changes
    unless ($self->{changes}) {
        return;
    }

    # no content
    if ( !$content ) {
        $content = $self->{content};
    }

    # open the file
    $file = $self->{var}.$self->{db}.'.json';

    # save
    open(_FH,">".$file) || die 'could not save';
    print _FH to_json($content);
    close(_FH);

    # changes
    $self->{changes} = 0;

}


##
## @brief get a file
##
sub file_get {
    my ($self, $file) = @_;

    open(FH,$file);
    my @f = <FH>;
    close(FH);

    return join("",@f);

}

##
## @brief pit a file
##
sub file_put {
    my ($self, $file, $content) = @_;

    open(FH,">".$file) || fail("Could not write to $file");
    print FH $content;
    close(FH);

}

1;