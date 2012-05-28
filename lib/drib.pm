# drib.pm

package drib;

# version
our $VERSION = "1.0";

# get our plugins and modules
use Module::Pluggable search_path => 'drib::cmd', sub_name => 'commands', require => 1;
use Module::Pluggable search_path => 'drib::plugin', sub_name => 'plugins', require => 1;
use Module::Pluggable search_path => 'drib::parser', sub_name => 'parsers', require => 1;

# stuff to use
use POSIX;
use User::pwent;
use Getopt::Long qw(GetOptionsFromArray :config pass_through permute);
use Data::Dumper;
use Term::ReadKey;
use Text::Wrap;
use File::Temp qw/ tempfile tempdir /;

# our own files
use drib::util;
use drib::packages;

##
## @brief new instance
##
sub new {
	my ($class, @args) = @_;
	my $self = {
        'config' => 0,
        'util' => 0,
        'user' => 0,
        'tmp' => "/tmp/drib",
        'argv' => ()
    }; 

    # bless
    bless $self;

    # user
    $self->{user} = ($ENV{SUDO_USER} ? $ENV{SUDO_USER} : $ENV{USER});    

    # temp dir
    $self->{tmp} = tempdir( CLEANUP => 0 );

    
    # return a blessed class
	return $self;
}

##
## @brief run drib as command line
##
sub run {
    my $self = shift;

    # if we don't have an arg we should
    # run our help
    if (scalar(@ARGV) == 0) {
        return $self->version(); # we have issues
    }
    
    # figure out 
    my %opts = (
        'plugins' => 1,
        'verbose' => 0,
        'version' => 0,
        'help' => 0,
        'config' => 0
    ); 
    
    # get em
    GetOptionsFromArray((\@ARGV, \%opts), ("plugins!","verbose","version","help|h","config=s"));

        # verbose
        if ($opts{verbose} == 1) {
            $self->{verbose} = 1;
        }

	# cmd
	my $cmd = lc(shift @ARGV);        

        # globalize argv for later
        foreach my $a (@ARGV) {
            if (substr($a,0,1) ne '-') {
                push(@{$self->{argv}}, $a);
            }
        }

    # log
    $self->log("looking for cmd '$cmd'");

	# loop through all of our commands
	# and see if we match
    foreach my $class ($self->commands()) { 

       # name
        my $name = $self->getNameFromClass($class);
        
        # tell them
        $self->log("found command '$class', with name '$name'");
        
        # if this command 
        if ($name eq $cmd) {
            $self->log("using class $class");            
            exit $class->new($self)->run();
        }
        
        # alias
        eval {
            my $a = $class."::alias";
            foreach my $ac (@{&$a()}) {
            	if ($ac eq $cmd) {
                    $self->log("using alias $ac -> $class");
                	exit $class->new($self)->run();
                }
            }
        }     

    }

    # version
    $self->version();

}

##
## @brief run a command
##
sub cmd {
    my $self = shift;
    my $cmd = shift;

    # loop through all of our commands
    # and see if we match
    foreach my $class ($self->commands()) { 

       # name
        my $name = $self->getNameFromClass($class);
        
        # if this command 
        if ($name eq $cmd) {
            return $class->new($self);
        }
        
        # alias
        eval {
            my $a = $class."::alias";
            foreach my $ac (@{&$a()}) {
                if ($ac eq $cmd) {
                    return $class->new($self);
                }
            }
        }     

    }

    # couldn't find command
    return 0;

}

##
## @brief package manager shortcut
##
sub packages {
    my $self = shift;

    unless ($self->{packages}) {
        $self->{packages} = new drib::packages($self);
    }

    return $self->{packages};

}

##
## #brief util shortcut
##
sub util {
    my $self = shift;

    # if it doesn't already exits
    unless ($self->{util}) {
        $self->{util} = new drib::util($self);
    }

    # create
    return $self->{util};

}

##
## @brief get config folder
##
sub config {
    my $self = shift;
    my $folder = shift || "/var/drib/";

    if ($self->{config}) {
        return $self->{config};
    }

    # dir
    unless ($dir) {
    
        # user
        my $pw = getpwnam($self->{user});
    
        # var and config    
        $dir = $pw->dir;
        
    }
    
    # dir
    $self->{var} = $self->path($dir).".drib/"; mkdir($self->{var});
    

    # open the config db
    $self->{config} = new drib::db($self->{var}, "config");

    # return the db ref
    return $self->{config};
}

##
## @brief show version number
##
sub version {
	my $self = shift;
	$self->message("drib package manager - version ".$VERSION);
	$self->message("copyright 2012 travis kuhl <travis\@kuhl.co>");
}

##
## @brief getNameFromClass
##
sub getNameFromClass {
    my ($self, $class) = @_;

    # name parts
    my @parts = split(/\:\:/, $class);
    
    # what's the name
    return pop(@parts);

}


##
## @brief make a path
##
sub path {
    my $self = shift;
    my $string = shift;
       $string =~ s/^\///;
    $string =~ s/\/$//;
    return "/".$string."/";    
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

##
## @brief trim slashes
##
sub slash_trim {
    my $self = shift;
    my $string = shift;
    $string =~ s/^\/+//;
    $string =~ s/\/$//;
    return $string; 
}

##
## @brief ask the user a question
##
sub ask {
    my ($self, $question, $default, $password) = @_;
    
    # ask it
    print $question . ($default ? " [$default]: " : ": ");
    
    if ( $password ) {
        `stty -echo`;
    }
    
    # wait for an answer
    my $answer = <STDIN>; chomp $answer;

    if ( $password ) {
        `stty echo`; print "\n";
    }
    
    # give it back
    return $answer || $default;
    
}

##
## @brief ask the user a yes/no question
##
sub ask_yn {
    my ($self, $question, $default) = @_;
    
    # ask it
    print $question . ($default ? " [$default]: " : ": ");
    
    # wait for an answer
    my $answer = <STDIN>; chomp($answer);
    
        # default
        $answer = $default unless $answer;
        
    # give it back
    return (lc(substr($answer,0,1)) eq "y" ? 1 : 0);
    
}

##
## @brief print a message
##
sub message {
    my $self = shift;
    my $msg = shift;

    # is it an array
    if (ref($msg) eq "ARRAY") {
        foreach my $m (@{$msg}) {
            $self->message($m);
        }
        return;
    }

    # get my termal size
    my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();    
    
    # don't go too far
    $wchar -= 10;
    
    # is =
    if ($msg eq "=") {
        $msg = ("="x$wchar);
    }
    else {
    
        # how long 
   	    $Text::Wrap::columns = $wchar;

        # msg
        $msg = wrap('', '', sprintf($msg, @_));
        
    }

    # print it 
    print $msg."\n";

}

##
## @brief log a message
##
sub log {
    my $self = shift;
    my $msg = shift;
    my $level = shift || LOG_DEBUG;
    
    # verbose
    if ($self->{verbose}==1) {
        print $msg."\n";
    }
        
}

##
## @brief random string generator
##
sub rand_str {    
    my $self = shift;
    my $length_of_randomstring= shift || 5; # the length of 
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

##
## @brief is string in array;
##
sub in_array {
    my ($self, $arr, $search_for) = @_;
    foreach my $value (@$arr) {
        return 1 if $value eq $search_for;
    }
    return 0;
}


##
## @brief dump var
##
sub dump {
    shift;
    print Dumper(@_); exit;
}

##
## @brief compare two version numbers
##
# --- copied from: Sort::Versions    ---
# --- below copyright applies to END ---
#  Copyright (c) 1996, Kenneth J. Albanowski. All rights reserved.  This
#  program is free software; you can redistribute it and/or modify it under
#  the same terms as Perl itself.
sub versioncmp {
    my $self = shift;
    my @A = ($_[0] =~ /([-.]|\d+|[^-.\d]+)/g);
    my @B = ($_[1] =~ /([-.]|\d+|[^-.\d]+)/g);

    my ($A, $B);
    while (@A and @B) {
    $A = shift @A;
    $B = shift @B;
    if ($A eq '-' and $B eq '-') {
        next;
    } elsif ( $A eq '-' ) {
        return -1;
    } elsif ( $B eq '-') {
        return 1;
    } elsif ($A eq '.' and $B eq '.') {
        next;
    } elsif ( $A eq '.' ) {
        return -1;
    } elsif ( $B eq '.' ) {
        return 1;
    } elsif ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
        if ($A =~ /^0/ || $B =~ /^0/) {
        return $A cmp $B if $A cmp $B;
        } else {
        return $A <=> $B if $A <=> $B;
        }
    } else {
        $A = uc $A;
        $B = uc $B;
        return $A cmp $B if $A cmp $B;
    }   
    }
    @A <=> @B;
}

# all good
return 1;