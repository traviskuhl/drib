# drib-cmd-settings

package drib::cmd::settings;


# base me
use base qw/drib::cmd/;

# use
use POSIX;
use File::Basename;
use JSON;
use File::Copy;

# export alaises
# what we can export
our @EXPORT = qw(alias);

sub alias {
    return ['set'];
}

##
## @brief create 
##
sub new {

    # make me
    my $self = shift;
    
    # super new
    $self->SUPER::new(shift); 
    
    # desc
    $self->{'desc'} = "Manage package settings";

    # define myself... i feel fat
    $self->{'cmds'} = {
    
        # !default
        'default' => {
            'sub' => 'cmd_set',
            'name' => 'set',
            'args' => [],
            'opts' => [            
            ],
            'desc' => "Set a package setting",
            'alias' => []
        },
       
    };

    # me
    return $self;    

}

##
## @brief run set command line
##
sub cmd_set {
	my $self = shift;
	my $opts = shift || {};

	# args
	my @args = @{$self->drib->{argv}};

	# no arguments means show all
	if (scalar @args == 0) {
		return $self->list();
	}

	# one argument means show list of package
	if (scalar @args == 1) {
		return $self->list($self->drib->packages->getPidFromArg(shift @args));
	}

	# loop through and set 
	foreach my $a (@args) {

	}

}

##
## @brief set a package variable
##
sub set {
	my $self = shift;
	my $pid = shift;
	my $name = shift;
	my $value = shift || 0;

	# open the package db
	my $db = $self->drib->packages->getPackage($pid);

	# one or more
	if (ref $name eq "HASH" && $value == 0) {
		foreach my $var (keys %{$name}) {
			$db->set($var, $name->{$var}, 'settings');
		}
	}
	else {
		$db->set($name, $value, 'settings');
	}

	# save
	$db->save();

	# done
	return 1;

}

##
## @brief list settings for a package or all packages
##
sub list {
	my $self = shift;
	my $pid = shift || 0;

	# get all packages
	my @packages = @{$self->drib->packages->db->get('packages')};

	# pid
	foreach my $_pid (@packages) {

		# get the package db
		my $db = $self->drib->packages->getPackage($_pid);

		# manifest
		my $m = $db->get('manifest');

		# vars
		my %vars = %{$db->all('settings')};

			# no vars
			unless (%vars || ($pid && $_pid != $pid)) {next;}

		# list
		$self->message("$m->{project}/$m->{name}");

		# loop through each of the settings
		foreach my $var (keys %vars) {	
			$self->message(" $var = ".$db->get($var, 'settings'));
		}

		# line
		$self->message();

	}

	return;

}

##
## @brief update setting files
##
sub files {
	my $self = shift;
	my $pid = shift;
	my $files = shift || [];
}

# i will always be true
return 1;