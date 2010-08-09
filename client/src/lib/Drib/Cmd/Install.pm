#
#  Drib::Cmd::Install
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package our install
package Drib::Cmd::Install;

# version
our $VERSION => "1.0";

# packages we need
use File::Basename;
use File::Find;
use POSIX;
use Digest::MD5 qw(md5_hex);
use Crypt::CBC;
use JSON;
use Getopt::Lucid qw( :all );
use Data::Dumper;

# drib
use Drib::Utils;

# new 
sub new {

	# get 
	my($ref, $drib) = @_;
	
	# self
	my $self = {
		
		# drib 
		'drib' => $drib,
		
		# shortcuts
		'tmp' => $drib->{tmp},					# tmp folder name
		'packages' => $drib->{packages},		# packages db
		
		# commands
		'commands' => [
			{ 
				'name' => 'install',
				'help' => '', 
				'alias' => ['i','in'],
				'options' => [
					Param('project|p'),
					Switch('cleanup|c'),
					Param('version|v'),
					Param('branch|b'),
					Switch('same|s'),
					Switch('downgrade|d'),
					Switch('depend|dep'),
				]
			},
			{
				'name' => 'remove',
				'help' => '',
				'alias' => ['r','rm'],
				'options' => [
					Switch('force|f'),
					Switch('yes|y'),
					Switch('unset|u'),
				]			
			},
			{
				'name' => 'list',
				'help' => '',
				'alias' => ['ls'],
				'options' => []			
			},
		]
		
	};

	# bless and return me
	bless($self); return $self;

}


##
## @brief parse the command line and execute proper sub
##
## @param $cmd the cammand given
## @param $opts command line opts
## @param @args list of arguments
##
sub run {

	# get some stuff
	my ($self, $cmd, $opts) = @_;

	# is cmd list or something simlar
	if ( $cmd eq "list" ) {
		$self->list(@{$self->{drib}->{args}});
	}
	else {
	
		# args
		my @args = @{$self->{drib}->{args}};
	
		# nothing in args means we don't know what to do
		if ( $#args == -1 ) {
			return {
				'code' => 404,
				'message' => "No package given!"
			};
		}
	
	    # unless they've told us yes, ask if they want to remove the packages
	    if ( $cmd eq "remove" && $opts->{yes} == 0 ) {
	        
	        # wait for an answer
	        my $resp = ask("Are you sure you want to remove ".($#packages+1)." ".plural("package",$#packages). " [y|n]: ");
	    	        
	        # what
	        if ( $resp ne "y" && $resp ne "yes" ) {
	            return {
	            	"code" => 412,
	            	"message" => "You said you don't want to remove them"
	            };
	        }
	    
	    }	
	
		# install for each one of the args
		foreach my $file (@args) {
			
			# msg
			my @msg = ();
			
			# try it
			if ( $cmd eq "remove" ) {
				
				# get a pid
				my $pkg = $self->{drib}->parsePackageName($file);
			
				# push it
				push(@msg, $self->remove($pkg->{pid})->{message});
				
			}
			else {
				push(@msg, $self->install($file, $opts)->{message});
			}
		
			# return to the parent with a general message
			return {
				'message' => join("\n",@msg),
				'code' => 0
			};
		
		}
		
	}

}

# install
sub install {

	# given a file
	my ($self, $file, $opts) = @_;

	# where are we now
	my $start_pwd = getcwd();  	

	# manifest
	my $manifest = 0;
	my $local = 0;
	
	# dist
	my $dist = $self->{drib}->{modules}->{Dist};

	# if package has .tar.gz
	# we don't need to go to dist
	if ( $file =~ /\.tar\.gz/ ) {    

        # where
        unless ( -e "./$file" ) {
            return {
            	"code" => 404,
            	"response" => "Package file $file does not exists"
            };
        }
     
        # get it 
        $tar = file_get($file);	
        
        # if cleanup
        if ( $opts->{cleanup} == 1 ) {
            `sudo rm $file`;
        }
        
        # manifest
        my $r = $self->{drib}->unpackPackageFile($tar);
        
        	# check the code
        	if ( $r->{code} != 200 ) {
        		return $r;
        	}
        
        # save it
        $manifest = $r->{manifest};
        
        # local
        $local = $file;
        $local =~ s/\.tar\.gz//;
        
        # add to manifest
        $manifest->{meta}->{local} = $local;
        
	}
	else {

        # get package name
        my $p = $self->{drib}->parsePackageName($file);
        
        # set it 
        $project    = $p->{project};
        $pkg        = $p->{name};
        $version    = $p->{version} || ( $opts->{branch} || 'current' );
    	    
    	# now we need to check with dist 
    	# to see if this package exists 
    	my $exists = $dist->check($project, $pkg, $version);
    
    	# if it exists we need to error
    	unless ( $exists ) {
    		return {
    			"code" => 404,
    			"message" => "Package $project/$pkg-$version does not exist."
    		};
    	}
    
    	# ok so we now have it 
    	# so lets get the file
    	$file = $dist->get($project, $pkg, $version);    
    
    	# unpack
    	my $r = $self->{drib}->unpackPackageFile($file);
    	
        	# check the code
        	if ( $r->{code} != 200 ) {
        		return $r;
        	}    		
    	
    	# set it 
    	$manifest = $r->{manifest};
    
    	# check if the package ist installed
    	my $installed = $self->{packages}->get($p->{pid});
    
    		# if yes is it the same version
    		if ( $installed ) {
    		
                # check if the same version is installed
                if ( $installed->{meta}->{version} eq $manifest->{meta}->{version} && !$options{'same'} ) {
                    return {
                    	"code" => 409,
                    	"message" => "$pkg-$installed->{meta}->{version} is already installed"
                    };
                }
                
                # check if the give version is smaller than the 
                # one installed
                if ( versioncmp($manifest->{meta}->{version},$installed->{meta}->{version}) == -1 && !$options{'downgrade'} ) {
                    return {
                    	"code" => 409,
                    	"message" => "$pkg-$exists is less than the installed version ($installed->{meta}->{version}).\nUse --downgrade to override."
                    };
                }
                
    		}
    		    		    	
    }

	# no manifest
	if ( $manifest == 0 ) {
		return {
			"code" => 500,
			"message" => "Manifest is unknow. Try Again."
		};
	}

	# lets see if there are any depend
	if ( $manifest->{depend} && $o_depend ) {

		# install
		my @install = ();

		# lets loop through and see if the packages
		# they've requested are installed
		foreach my $item ( @{$manifest->{depend}} ) {

			# parse a package name
			my $p = $self->{drib}->parsePackageName($item->{pkg});

			# package
			my $i = $drib->{packages}->get($p->{pid});

			# min and max
			my $min = $item->{min} || 0;
			my $max = $item->{max} || 0;
			my $ver = $item->{version} || 0;

			# if it's insatlled we need to check
			# min and max
			if ( $i ) {

				# is there a min and max
				if ( $ver != 0 && $ver != $i->{meta}->{version} ) {
					return {
						"code" => 409,
						"message" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} version requirement ($min)"
					};
				}			

				# is there a min and max
				if ( $min != 0 && versioncmp($i->{meta}->{version},$min) == -1 ) {
					return {
						"code" => 409,
						"message" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} minimun requirement ($min)"
					};
				}

				# is there a min and max
				if ( $max != 0 && versioncmp($max,$i->{meta}->{version}) == -1 ) {
					return {
						"code" => 409,
						"message" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} maximum requirement ($max)"
					};
				}				

			}
			else {

				# is there a version
				if ( $ver == 0 ) {
					$ver = $opts->{'branch'} || 'current';
				}

				# package name
				my $pn = $p->{project} ."/" . $p->{name} . "-" . $ver;

				# push to install
				push(@install,$pn);

			}

		}

		# are their files to install
		if ( $#install != -1 ) {		

			# install
			foreach my $p ( @install ) {

				# return
				my $r = $self->install($p);

				# try to install
				msg($r->{response});

			}

			# move back to start pwd
			chdir $start_pwd;
			
			# no depend
			$opts->{depend} = 0;

			# now try reinstalling the package file
			return $self->install($pkg_file, $opts);		

		}

	}


	# get a package name
	my $p = $self->{drib}->parsePackageName($manifest->{project}."/".$manifest->{meta}->{name});

	# check if the package ist installed
	my $installed = $self->{packages}->get($p->{pid});

		# installed we should remove
		if ( $installed ) {
			$self->remove( $p->{pid} );
		}

	# run pre-install commands
	$self->{drib}->{modules}->{Command}->exec('pre-install', $manifest);

	# now lets get a list of all directories
	# and move them into place
	opendir(my $dh, '.');
	my @dirs = readdir($dh);
	close($dh);
	

	# loop and move each of the 
	# files to root. we force the 
	# move. so if any existing folders 
	foreach my $d ( @dirs ) {
		if ( $d ne '.' && $d ne '..' && -d $d ) {	
			`sudo cp -rf ./$d /`;
		}
	}
	

    # make a pid
    my $pid = $self->{drib}->getPid($manifest->{project},$manifest->{meta}->{name});
    
    # don't need raw or changelog
    $manifest->{raw} = "";
    $manifest->{changelog} = "";
    
	# add package to our package db
	$self->{packages}->set($pid, $manifest);
    
    # set it 
    $self->{packages}->add($manifest->{meta}->{name}, $pid, 'map');

	# get settings for this file 
	my $curset = $self->{drib}->{modules}->{Setting}->get($pid) || {}; 

    # any settings should always stay the same
    foreach $k ( keys %{$manifest->{set}} ) {
	    unless ( defined $curset->{$k} ) {
			$curset->{$k} = $manifest->{set}->{$k};
    	}
    }
    
    # set settings
    $self->{drib}->{modules}->{Setting}->set($pid, $curset);
    
    # set files
    $self->{drib}->{modules}->{Setting}->files($pid, $manifest->{set_files});

	# add crons
	$self->{drib}->{modules}->{Cron}->add($pid, $manifest->{crons} );

    # cleanup our tmp dir
    `sudo rm -fr $tdir`;    
    
	# run pre-install commands
	$self->{drib}->{modules}->{Command}->exec('post-install', $manifest);    
    
	# tell them what up
	return {
		"code" => 200,
		"message" => "Package $manifest->{meta}->{project}/$manifest->{meta}->{name} installed!"
	};


}


##
## @brief remove a package
##
## @param $pid package id
## @param $opts options
##
sub remove {

	# get packages
	my ($self, $pid, $opts) = @_;
    
    # get the manifest 
    my $manifest = $self->{packages}->get($pid);

		# no manifest means no package
		unless ( $manifest ) {
			return {
				'code' => 404,
				'message' => "Package does not exists"
			}
		}

    # dirs
    my @dirs = ();

    # loop through the files array and remove
    # any files. after we'll loop through 
    foreach my $f ( @{$manifest->{files}} ) {
        
        # is a directory
        if ( -d $f ) {
            push @dirs, $f;
        }
        else {        
#            `sudo rm -f --preserve-root $f`;
        }
        
    }
     
    # now any directories
    foreach my $d ( @dirs ) {  
            
        # remove the dir
       	rmdir($d);
        
    }

    # check if they want us to remove
    # the settings
    if ( $opts->{'unset'} ) {
		$self->{drib}->{modules}->{Setting}->unset($pid);        
    }
    
    # now remove the package from the packages db
    $self->{packages}->unset($pid);
    
    # remove crons
    $self->{drib}->{modules}->{Cron}->remove($pid);
    
    # message
    return {
    	'code' => 200,
		"message" => "Package $manifest->{meta}->{project}/$manifest->{meta}->{name} removed!"
    };

}

##
## @brief list all installed packages
##
## @param $args list of command args
##
sub list {

	# args
	my ($self, @args) = @_;


    # project
    my $project = shift @args || 'all'; 
        
    # get a list of packages
    my $packages = $self->{packages}->all('default');
    
    # array
	my %projects = ();
	my $total = 0;
    
    # loop
    foreach my $pid ( keys %{$packages} ) {
    
        # get the package            
        my $p = $packages->{$pid};        

		# either we're showing all
		# or we aren't showing all and we're showing the package
		if ( $project eq "all" || ( $project ne 'all' && $project eq $p->{project} ) && $p->{project} ) {

			# push to projects
			$projects{$p->{project}} = () unless defined $projects{$p->{project}};

	    	# add it
			$projects{$p->{project}}{$pid} = 1;

	    	# one more
	    	$total++;

	    }
    
    }
    
    # print it 
    msg("-"x40);      
    msg("Total of $total Packages installed.");       
    msg("-"x40);      
            
    # print them
    foreach my $pr ( keys %projects ) {
		
		if ( $pr ) {
			
			# name
			msg( $pr );
	
			# each package
			foreach my $pid ( keys %{$projects{$pr}} ) {
	
				# local
				my $local = "";
	
					# if local
					if ( defined $packages->{$pid}->{meta}->{local} ) {
						$local = " (Build: ".$packages->{$pid}->{meta}->{local}.")";
					}
	
				if ( $packages->{$pid}->{meta}->{version} != 0 ) {
					msg(" ".$packages->{$pid}->{meta}->{name}."-".$packages->{$pid}->{meta}->{version}.$local);
				}
				else {
					msg(" ".$packages->{$pid}->{meta}->{name}.$local);
				}
			}
	
			msg();
			
		}

    }

	# exit out
	exit;

}