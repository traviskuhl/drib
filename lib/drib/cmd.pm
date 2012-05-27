# drib::cmd

package drib::cmd;

# use some stuff
use Getopt::Long qw(GetOptionsFromArray :config pass_through permute);
use User::pwent;
use Term::ReadKey;
use Text::Wrap;


# new 
sub new {    
    
    # new it up
    my drib::cmd $self = shift;

    # req
    $self->{drib} = shift;
    
    # return
    return $self;

}

##
## @brief run a command
##
sub run {
    my $self = shift;
    my $cmd = shift || $ARGV[0] || 'default';        
        
    # if no command
    # go for help
    unless (exists $self->{cmds}->{$cmd}) {    
        if (exists $self->{cmds}->{'default'}) {
            $cmd = 'default';    
        }
        else {    
            return $self->help();
        }
    }        
    
    # args
    my @args = ();
    my @cleaned = ();

    # loop through args and find
    # anything that isn't an opt
    foreach my $a (@ARGV) {
        if (substr($a,0,1) ne '-') {
            push(@args, $a);
        }
        else {
            push(@cleaned, $a);
        }
    }

    # vars holder
    my %vars = ();
    my @opts = (\@cleaned, \%vars);

    # send to getopts
    GetOptionsFromArray((@opts,@{$self->{cmds}->{$cmd}->{opts}}));    
    
    # i
    my $i = 0;
    
    # loop throug my args and add them to vars
    foreach my $name (@{$self->{cmds}->{$cmd}->{args}}) {
        $vars{$name} = $args[$i++];
    }

    # sub 
    my $sub = $self->{cmds}->{$cmd}->{sub};

    # call the func
    return $self->$sub(\%vars);

}

##
## @brief shortcut to drib
##
sub drib {
	return shift->{drib};
}

##
## @brief dump (passthrough to drib->dump)
##
sub dump {
	my $self = shift;
	return $self->drib->dump(@_);
}

##
## @brief print a message (passthrough to drib->message)
##
sub message {
	my $self = shift;
	return $self->drib->message(@_);
}

##
## @brief print to log (passthrough to drib->log)
##
sub log {
	my $self = shift;
	return $self->drib->log(@_);
}

##
## @brief make a path
## 
sub path {
    my $self = shift;
    my $parts = shift || [];
    my @final = ();
    foreach my $part (@{$parts}) {
        push(@final, $self->drib->slash_trim($part));
    }
    return "/".join("/", @final)."/";
}

return 1;