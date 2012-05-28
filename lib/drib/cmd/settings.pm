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

	# pid 
	my $pid = $self->drib->packages->getPidFromArg(shift @args);


	# settings
	my $set = {};

	# loop through and set 
	foreach my $a (@args) {
		my ($name, $val) = split(/\=/, $a);
		$set->{$name} = $val;
	}

	# save
	$self->set($pid, $set);

	# list
	$self->list($pid);

}

##
## @brief set a package variable
##
sub set {
	my $self = shift;
	my $pid = shift;
	my $name = shift;
	my $value = shift || 0;
	my $files = shift || 1;

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

	# buildFiles
	if ($files == 1) {
		$self->_buildFiles();	
	}

	# settings text file
	$self->_buildTextFile();

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

	# get our package db	
	my $db = $self->drib->packages->getPackage($pid);	

	# set it 
	$db->set("set_files", $files);

	# done
	$db->save();

	# buildFiles
	$self->_buildFiles();

	# done
	return;

}

##
## @brief build settings files
##
sub _buildFiles {
	my $self = shift;
	my $pid = shift;

	# get our package db	
	my $db = $self->drib->packages->getPackage($pid);	

	# files
	my $files = $db->get("set_files");	

	# settings
	my $settings = $db->all('settings');

    # open each file
    foreach my $item ( @{$files} ) {
            
        # file
        my $file = $item->{file};
        
        # content            
        my $content =  $item->{tmpl};
    
        # loop through each setting
        foreach my $key ( keys %{$settings} ) {
            $content =~ s/\$\($key\)/$settings->{$key}/g;
        }
        
        # write back the file
        $self->drib->file_put($file, $content);
    
    }

}

##
## @brief rebuild settings files
##
sub _buildTextFile {
	my $self = shift;

	# file
	$txt = "";

    # get all packages
	my @packages = @{$self->drib->packages->db->get('packages')};

    # print them
    foreach my $pid ( @packages ) {
      
        # settings
        my $db = $self->drib->packages->getPackage($pid);

        # manifest
        my $man = $db->get('manifest');

        # settings
		my $settings = $db->all('settings');    
        
        # only show if we have at least one setting
        if ( $settings && ( ref $settings eq "HASH" && scalar(keys %{$settings}) > 0 ) ) {
        
            # loop and show
            foreach my $key ( keys %{$settings} ) {
                
                # key
                $keyn = $key;
                
                # replace any .
                $keyn =~ s/\./\_/g;
                
				# set it 
				$txt .= $man->{project}."_".$man->{name}."__".$keyn."|".$settings->{$key}."\n";
                
            }

        }
        
    }	
    
	# what's our var
    my $var = $self->drib->path($self->{drib}->config->get("var") || "/var/drib");

    # where is the flat settings file
	my $file = "$var/settings.txt";

	# save it
	$self->drib->file_put($file, $txt);

}

# i will always be true
return 1;