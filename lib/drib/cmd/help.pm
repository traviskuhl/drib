# drib::cmd::help

package drib::cmd::help;

# use our base cmd
use base qw/drib::cmd/;

##
## @brief create a new backyard
##
sub new {

    # make me
    my $self = shift;
    
    # super new
    $self->SUPER::new(shift); 
    
    # desc
    $self->{'desc'} = "Show this help message";

    # define myself... i feel fat
    $self->{'cmds'} = {
    
        # !default
        'default' => {
            'sub' => 'cmd_help',
            'name' => 'help',
            'args' => [],
            'opts' => [],
            'desc' => "Show help message",
            'alias' => []
        },
       
        
    
    };
    
    return $self;
        
}

##
## @brief show help message
##
sub cmd_help {
	my ($self) = @_;
	
    # show version
    $self->drib()->version();
        
    # useage 
    $self->message("\nsage: drib [--help] [--version] <command> [<sub-command>] [<args>]\n");   
    
    # message
    $self->message("See 'by help <command>' for help with a specific command.\n");
    
    # and done
    exit;

}

return 1;