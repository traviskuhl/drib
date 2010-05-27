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

# things we need
use Drib::Utils;


###############################################################
### @brief install a package 
###
### @param $args
###			{
###				'file' => path to package file
###				'project' => name of project
###				'name' =>  name of package
###				'version' => version number of package
###				'branch' => package branch
###			}
###
### @return response object
###############################################################
sub execute {
	
	# given a file
	my ($args) = @_;
	
	# get commands
	my ($pkg,$version,$file,$project);
	
	# check for host
	if ( $options{'host'} ) {
		
		# remove host
		$ocmd =~ s/-h(ost)?=?.*//gi;
		
		# host
		my $h = new drib::host($options{'host'});
		
		# cmd
		$cmd = "sudo drib " . $ocmd;
		
		# run the command
		my ($r,$msg) = $h->cmd($cmd);
		
		# tell them
		if ( $r ) {
			return {
				"code" => 200,
				"response" => "$pkg_file was installed on $options{'host'}",
			}
		}
		else {
			return {
				"code" => 400,
				"response" => "$pkg_file could not be installed on $options{'host'}"
			};
		}
	
	}
	
	# where are we now
	my $start_pwd = getcwd();  	
	
	# manifest
	my $manifest = 0;
	my $local = 0;
	
	# if package has .tar.gz
	# we don't need to go to dist
	if ( $pkg_file =~ /\.tar\.gz/ ) {    
	    
        # where
        unless ( -e "./$pkg_file" ) {
            return {
            	"code" => 404,
            	"response" => "Package file $pkg_file does not exists"
            };
        }
     
        # get it 
        $file = file_get($pkg_file);	
        
        # if cleanup
        if ( $options{'cleanup'} ) {
            `sudo rm $pkg_file`;
        }
        
        # manifest
        my $r = _unpack_package_tar($file);
        
        # save it
        $manifest = $r->{manifest};
        
        # local
        $local = $pkg_file;
        $local =~ s/\.tar\.gz//;
        
        # add to manifest
        $manifest->{meta}->{local} = $local;
        
	}
	else {
	
        # get package name
        my $p = _parse_pkg_name($pkg_file);
        
        # set it 
        $project    = $p->{project};
        $pkg        = $p->{name};
        $version    = $p->{version} || 'current';
    	
        # check for external projects
        if ( in_array(\@external::PROJECTS,$project) ) {
        
            # what happeend
            return &external::_map($project,$pkg,$version);
            
        }    
    
    	# now we need to check with dist 
    	# to see if this package exists 
    	my $exists = $DIST->check($project,$pkg,$version);
    
    	# if it exists we need to error
    	unless ( $exists ) {
    		return {
    			"code" => 404,
    			"response" => "Package $pkg-$version does not exist."
    		};
    	}
    
    	# ok so we now have it 
    	# so lets get the file
    	$file = $DIST->get($project,$pkg,$version);    
    
    	# unpack
    	my $r  = _unpack_package_tar($file);
    	
    	# set it 
    	$manifest = $r->{manifest};
    
    	# check if the package ist installed
    	my $installed = $PACKAGES->get($p->{pid});
    
    		# if yes is it the same version
    		if ( $installed ) {
    		
                # check if the same version is installed
                if ( $installed->{meta}->{version} eq $manifest->{meta}->{version} && !$options{'same'} ) {
                    return {
                    	"code" => 409,
                    	"response" => "$pkg-$installed->{meta}->{version} is already installed"
                    };
                }
                
                # check if the give version is smaller than the 
                # one installed
                if ( versioncmp($manifest->{meta}->{version},$installed->{meta}->{version}) == -1 && !$options{'downgrade'} ) {
                    return {
                    	"code" => 409,
                    	"response" => "$pkg-$exists is less than the installed version ($installed->{meta}->{version}).\nUse --downgrade to override."
                    };
                }
                
    		}
    		    		    	
    }

	# no manifest
	if ( $manifest == 0 ) {
		return {
			"code" => 500,
			"response" => "Manifest is unknow. Try Again."
		};
	}
	
	# lets see if there are any depend
	if ( $manifest->{depend} ) {
		
		# install
		my @install = ();
		
		# lets loop through and see if the packages
		# they've requested are installed
		foreach my $item ( @{$manifest->{depend}} ) {
			
			# parse a package name
			my $p = _parse_pkg_name($item->{pkg});
			
			# package
			my $i = $PACKAGES->get($p->{pid});
			
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
						"response" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} version requirement ($min)"
					};
				}			
			
				# is there a min and max
				if ( $min != 0 && versioncmp($i->{meta}->{version},$min) == -1 ) {
					return {
						"code" => 409,
						"response" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} minimun requirement ($min)"
					};
				}

				# is there a min and max
				if ( $max != 0 && versioncmp($max,$i->{meta}->{version}) == -1 ) {
					return {
						"code" => 409,
						"response" => "Installed version of $i->{meta}->{name} ($i->{meta}->{version}) does not meet $manifest->{meta}->{name} maximum requirement ($max)"
					};
				}				
				
			}
			else {
				
				# is there a version
				if ( $ver == 0 ) {
					$ver = $options{'branch'} || 'current';
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
				my $r = _do_install($p);
				
				# try to install
				msg($r->{response});
			
			}
			
			# move back to start pwd
			chdir $start_pwd;			
			
			# now try reinstalling the package file
			return _do_install($pkg_file);		
			
		}
	
	}
	
	
	# get a package name
	my $p = _parse_pkg_name($manifest->{project}."/".$manifest->{meta}->{name});
	
	# check if the package ist installed
	my $installed = $PACKAGES->get($p->{pid});
	
		# installed we should remove
		if ( $installed ) {
		    
			# since we're still moving on
			# we need to remove the current file
			my @rm = ($p);	
			
			# remove 
			_remove(\@rm);		   

		}
	
	# check if it's a secure package
	if ( $manifest->{secure} != 0 && -e $tdir."/encrypted" ) {
	
		# ask for the passphrase 
		my $passphrase = md5_hex( ask("This package is secured, please enter the Passphrase:",1) );

		# now try to encrypt that tar file
		my $cipher = Crypt::CBC->new( 
			-key 	=> $passphrase,
			-cipher => 'Blowfish'
		);
	
		# open the encrypted file
		my $enc = file_get("$tdir/encrypted");
	
		# try to unencrypt the file
		my $tar = $cipher->decrypt($enc);
	
		# now put it pack
		file_put("$tdir/secure.tar",$tar);
	
		# try to untar it 
		`sudo tar -xf $tdir/secure.tar 2>/dev/null`;
	
		# check for a good file
		if ( -e "$tdir/secure/.good" ) {
		
			# move everything from secure into tdir
			`sudo mv -f $tdir/secure/* $tdir`;		
					
			# remove some files
			`sudo rm -rf $tdir/.good $tdir/encrypted $tdir/secure $tdir/secure.tar`;
			
			# should be good to go now
		
		}
		else {
			return {
				"code" => 403,
				"response" => "The Passphrase you tried for '".$manifest->{meta}->{name}."' was incorrect. Try again!"
			};
		}
	
	}
	
	
	# run pre-install commands
	_exec_commands($manifest,'pre-install');
	
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
    my $pid = _get_pid($manifest->{project},$manifest->{meta}->{name});
    
    # don't need raw or changelog
    $manifest->{raw} = "";
    $manifest->{changelog} = "";
    
	# add package to our package db
	$PACKAGES->set($pid,$manifest);
    
    # set it 
    $PACKAGES->add($manifest->{meta}->{name},$pid,'map');

	# get settings for this file 
	my $curset = $SETTINGS->get($pid) || {}; 

    # any settings should always stay the same
    foreach $k ( keys %{$manifest->{set}} ) {
	    unless ( defined $curset->{$k} ) {
			$curset->{$k} = $manifest->{set}->{$k};
    	}
    }
    
    # set settings
    $SETTINGS->set($pid,$curset);
    
    # set files
    $SETTINGS->set($pid,$manifest->{set_files},'files');
    
    # _update_settings_txt_file
    _update_settings_txt_file();

    # perform set file updates
    _write_settings_files($manifest->{set_files},$curset);

	# cron 
	if ( $manifest->{crons} ) {

		# crons 
		my @crons = ();

		# loop me
		foreach my $c ( @{$manifest->{crons}} ) { 
			push(@crons,$c->{cmd});
		}	

		# add to package list
		$CRONS->set($pid,\@crons);
	
		# update
		_rebuild_crons();
	
	}


    # cleanup our tmp dir
    `sudo rm -fr $tdir`;    
    
	# run pre-install commands
	_exec_commands($manifest,'post-install');    

	# tell them what up
	return {
		"code" => 200,
		"response" => "Package $manifest->{meta}->{name} installed!"
	};
	
}
