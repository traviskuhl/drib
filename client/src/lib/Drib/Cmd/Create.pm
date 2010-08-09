#
#  Drib::Cmd::Create
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package
package Drib::Cmd::Create;

# version
our $VERSION => "1.0";

# packages we need
use File::Basename;
use File::Find;
use File::Spec;
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
	my($ref,$drib) = @_;
	
	# self
	my $self = {
		
		# drib 
		'drib' => $drib,
		
		# shortcuts
		'tmp' => $drib->{tmp},
		
		# commands
		'commands' => [
			{ 
				'name' => 'create',
				'help' => '', 
				'alias' => ['cr','c'],
				'options' => [
					Param('project|p'),
					Switch('install|i'),
					Switch('dist|d'),
					Switch('cleanup|c'),
					Param('type|t')
				]
			}
		]
		
	};

	# bless and return me
	bless($self); return $self;

}

##
## @brief run the create 
##
sub run {
	
	# get some stuff
	my ($self, $cmd, $opts) = @_;
	
	# arsgs
	my @args = @{$self->{drib}->{args}};

	# files
	my @files = ();
	
	# pwd
	my $pwd = getcwd();
	
	# is there a file that matches any of our
	# avail parsers in the directory
	my $p = join "|", keys %{$self->{drib}->{parsers}};	
	
	# see if they gave us a list of files
	if ( scalar @args == 0 ) {
			
		# open the directory and see if there's a pkg file	
		opendir(my $dh, $pwd);
		@files = grep { $_ =~ /\.($p)/ } readdir($dh);
		closedir $dh;
		
	}
	else {
	
		# args must be files
		@files = @{$self->{drib}->{args}};
		
	}
	
	# still no files, try recursing into the directory
	if ( $#files == -1 ) {

		my $r = ask("Would you like to recursivly build all files in this directory. [n]");

		# ask if they want to build the directory
		if ( lc(substr($r,0,1)) eq "y" ) {

			# search the directory
			foreach my $f ( @{search_dir($pwd,"*.$p")} ) {
				my @n = split(/\//,$f);

				if ( lc(substr(ask(" Build $n[$#n] [y]:"),0,1)) ne 'n' ) {
					push(@files,$f);
				}
			}

		}

	}	

	# if we still have no luck.
	# return back to the parent
	if ( $#files == -1 ) {
		return {
			'message' => "Could not find any package files",
			'code' => 404
		};
	}
	
	# loop through the files and create each one
	# and print the status message each time
	foreach my $file (@files) {
		
		# msg
		my @msg = ();
		
		# try it
		push(@msg, $self->create($file,$opts)->{message});
	
		# return to the parent with a general message
		return {
			'message' => join("\n",@msg),
			'code' => 0
		};
	
	}
	
}



##
## @brief create a package
##
sub create {

	# file
	my ($self, $file, $options) = @_;

	# optns
	my $dist		= $options->{dist};
	my $type		= $options->{type} || 'release';
	my $install 	= $options->{install} || 0;

	# where are we now
	my $pwd = getcwd();    		

	# make sure we're in the correct folder
    my ($fname,$fpath) = fileparse($file);	

    # move into fpath
    chdir $fpath;

	# open the manifest
	my $man = file_get($fname);

	# check if the first two chars are 
	# a hash bang
	if ( substr($man,0,2) eq "#!" ) {
		$man = `sudo $file`;
	}

	# save the man as a tmp file
	my $tmp = $self->{tmp} . "/" . rand_str(5);

	# put the man
	file_put($tmp,$man);

	# parse me 
	my $p = $self->{drib}->parsePackageFile($file, $tmp);
	
		# if no
		if ( $p == 0 ) {
			return {
				'code' => 500,
				"message" => "Could not parse the package file"
			};
		}

	# what we need 
	# this is just to keep backwards compatable 
	# with perl parser
	my $Meta		= $p->{meta};
	my $Set 		= $p->{set};
	my $Dirs 		= $p->{dirs};
	my $Files		= $p->{files};
	my $Commands	= $p->{cmd};
	my $Depend 		= $p->{depend};
	my $Cron 		= $p->{cron};

	# we need the package name
	my $pkg		= $Meta->{name};
	my $version = $Meta->{version};
	my $project = $options->{project} || $self->{drib}->{modules}->{Config}->get('project');
	my $vff = 0;

		# figure if version is a file we have to look in
		if ( $version =~ /file\:/ ) {

			# remove the file
			$version =~ s/file\://;				

			# open the file 
			my $f = file_get($version) =~ /Version ([0-9\.]+)/i;

			# get the version file
			$vff = $pwd .'/'. $version;			

			# set hte verison
			$version = $Meta->{version} = $1;	

		}

	   # is project defined in meta
	   if ( exists $Meta->{project} ) {
	       $project = $Meta->{project};
	   }

    # version
    if ( $type eq "symlink" || $type eq "s" ) {
        $version = "$version.S".time();        
        $dist = 0;
    }
    elsif ( $type eq "beta" || $type eq "b" ) {
    
        # version
        $version = "$version.B".time();
        
        # branch
        $branch = "beta";
        
    }
    elsif ( $type eq "nightly" || $type eq 't' ) {
    
        # version
        $version = "$version.N".time();    
        
        # bracnh
        $branch = "nightly";
        
    }
    elsif ( $type eq "qa" || $type eq 'q' ) {
    
        # version
        $version = "$version.QA".time();    
        
        # bracnh
        $branch = "qa";
        
    }

	# set version
	$Meta->{version} = $version;

	# pass
	my $passphrase = 0;

	# check if this is a secure pacakge
	if ( defined $Meta->{secure} ) {
		$passphrase = md5_hex( ask("Enter a Passphrase for this package:",1) );
	}
	else {
		$Meta->{secure} = 0;
	}

	# now we need to create a tmp director
	my $tdir_name = rand_str(10);
	my $tdir = $self->{tmp} . "/" . $tdir_name;

	# create the dir
	mkdir($tdir);

	# listsings of what we've created
	my @listing = ();

	# now create and dirs they want
	if ( $Dirs != 0 ) {
		foreach my $dir ( @{$Dirs} ) {

			# ref
			unless ( ref($dir) eq "HASH" ) {
				$dir = { 'dir' => $dir };
			}

			# name		
			my $d = $tdir . "/" . trim($dir->{dir},1)."/";

			# mkdir 
			`sudo mkdir -p $d`;

				# if user
				if ( defined $dir->{user} ) {
					`sudo chown $dir->{user} $d`;
				}

				# group
				if ( defined $dir->{group} ) {
					`sudo chown :$dir->{group} $d`;
				}

				# mode
				if ( defined $dir->{mode} ) {
					`sudo chmod $dir->{mode} $d`;
				}

			# add listing
			push(@listing,$d);

		}
	}

	# setting files
	my @SettingFiles = ();

	# no files
	if ( $Files != 0 ) {
		foreach my $f ( @{$Files} ) {

			# where are we going
			my $d = $tdir . trim($f->[0]);

			# if the dest doesn't exist 
			# we need to create it 
			unless ( -e $d ) {				
				`sudo mkdir -p $d`;			
			}

			# all the files
			my @files = ();

			# now figure out if src is a
			# single file or a ref
			unless ( ref($f->[1]) eq "HASH" ) {
				$f->[1] = {'src'=>$f->[1]};
			}

			# files
			my $file = $f->[1];

			# check if we have one file or many
			if ( defined $file->{src} ) {

				# add it
				push(@files,$file);

			}
			else {

				# check for lfind
				if ( defined $file->{find} ) {

					# run the find
					my $r = `sudo find $file->{find}`;
					my $root = "";

					# root 
					if ( defined $file->{root} ) {
					   $root = trim($file->{root});
					}
					
					# each file
					foreach my $item ( split(/\n/,$r) ) {

                        # parse the file path
                        my ($fname,$fpath) = fileparse($item);
                        
                        # append
                        $append = "";
                        
                        # if path does not eq root
                        # we need to append the subdir to the 
                        # final dest also
                        if ( $root ne "" && trim($fpath) ne $root ) {
                            $fpath =~ s/$root//;
                            $append = $fpath;
                        }
                                      

                        # push ontop
						push(@files,{
                            'src'=> $item,
                            'user'=>$file->{user},
                            'group'=>$file->{group},
                            'mode'=>$file->{mode},
                            'append'=>$append,
                            'settings' => $file->{settings}
                        });

					}
								

				}
				elsif ( defined $file->{'glob'} ) {

				    # glob it up
				    my @r = glob $file->{'glob'};				    
					my $root = "";

					# root 
					if ( defined $file->{root} ) {
					   $root = trim($file->{root});
					}

					# each file
					foreach my $item ( @r ) {

                        # parse the file path
                        my ($fname,$fpath) = fileparse($item);
                        
                        # append
                        $append = "";
                        
                        # if path does not eq root
                        # we need to append the subdir to the 
                        # final dest also
                        if ( $root ne "" && trim($fpath) ne $root ) {
                            $fpath =~ s/$root//;
                            $append = $fpath;
                        }

                        # push ontop
						push(@files,{
                            'src'=>$item,
                            'user'=>$file->{user},
                            'group'=>$file->{group},
                            'mode'=>$file->{mode},
                            'append'=>$append,
                            'settings' => $file->{settings}
                        });

					}				    

				}

			}

			# loop through each file
			foreach my $item ( @files ) {

				# filename
				my $n = basename($item->{src});

				# dest
				my $_d = "$d/$n";

				# check for append
				if ( defined $item->{append} && $item->{append} ne "" ) {

				    # append
				    $_d = File::Spec->rel2abs(trim($d)."/".trim($item->{append},1)."/")."/";

				    # append name
				    $_d .= $n;

				}

				# push
				push(@listing,$_d);

				my $isSet = 0;

				# settings
                if ( defined $item->{settings} && $item->{settings} eq 'true' ) {
                
                    # dest file
                    my $sfd = $_d;
                       $sfd =~ s/$tdir//g;
                       
                    # push it 
                    push(@SettingFiles,{'file' => $sfd, 'tmpl' => file_get($item->{src}) });
                    
                    # isset 
                    $isSet = 1;
                    
                }               
                
                # dest dir
                $_dir = dirname($_d);
                	
                	unless ( -d $_dir ) {
                		`mkdir -p $_dir`;
                	}
                
                # now see what type of build we have
                if ( ( $type eq 'symlink' || $type eq 's' ) && $isSet != 1 ) {
                    my $_s = getcwd() . "/" . $item->{src};			
                    symlink $_s, $_d;
                }
                else {	
    				`sudo cp $item->{src} $_d`;
                }

				# if user
				if ( defined $item->{user} ) {
					`sudo chown $item->{user} $_d`;
				}

				# group
				if ( defined $item->{group} ) {
					`sudo chown :$item->{group} $_d`;
				}

				# mode
				if ( defined $item->{mode} ) {
					`sudo chmod $item->{mode} $_d`;
				}

		        # rename
		        if ( defined $item->{rename} ) {
                    `sudo mv $_d $d/$item->{rename}`;
		        }

			}

		}
	} # END @files	


#	print Dumper(@listing); die;

	# nice list of files
	my @nicelist = map { s/$tdir//g; $_; } @listing;

	# move to our folder
	chdir $tdir;	

	# if they want a secure package
	# we need to move everything into a secure directory
	if ( $passphrase != 0 ) {

		# make secure
		`sudo mkdir $tdir/secure`;

		# move all files and dirst that are not secure
		opendir(my $dh, $tdir);
			foreach my $xf ( readdir($dh) ) {
				if ( $xf ne "." && $xf ne ".." && $xf ne "secure" ) {			
					`sudo mv $tdir/$xf $tdir/secure`;
				}
			}
		closedir($dh);

		# add our good file
		file_put("$tdir/secure/.good","1");

		# now tar just that file
		`sudo tar -cf secure.tar ./secure`;

		# now try to encrypt that tar file
		my $cipher = Crypt::CBC->new( 
			-key 	=> $passphrase,
			-cipher => 'Blowfish'
		);

		# get the securet
		my $sec_file = file_get($tdir."/secure.tar");

		# do it 
		my $encrypted = $cipher->encrypt($sec_file);

		# remove the tar and save back
		`sudo rm -rf $tdir/secure`; 	
		`sudo rm $tdir/secure.tar`;

		# put it in there
		file_put($tdir."/encrypted",$encrypted);

	}

    # changelog
	$cl = file_get($pwd.'/'.$Meta->{changelog}) || "";

	# need to create our own version of the manifest
	my $manifest = {
	    'project' => $project,
		'type' => $type,
		'name' => $Meta->{name},	
		'meta' => $Meta,
		'secure' => $Meta->{secure},
		'set' => $Set,
		'set_files' => \@SettingFiles,
		'crons' => $Cron,
		'commands' => $Commands,
		'raw' => $man,
		'changelog' => $cl,
		'depend' => $Depend,
		'buildenv' => {
			'user' => $ENV{'USER'},
			'host' => $ENV{'HOSTNAME'},
			'pwd' => $ENV{'PWD'}			
		},
		'ov' => $vff,
		'files' => \@nicelist
	};

	# add our manifest to the build 
	file_put($tdir."/.manifest", to_json($manifest) );

	# name 
	my $name = "$pkg-$version";

	# tar 
	`sudo tar -czf $name.tar.gz .`;

	# package
	my $package = "$tdir/$pkg-$version.tar.gz";

    # or move the file back to the pwd 
	`sudo mv $package $pwd`;
		
	# remove our tmp dir
	`sudo rm -r $tdir`;

    # move back to current
    chdir $pwd;

	# dist
	if ( $options->{dist} == 1 ) {
		
		# message created
		msg("Package Created: $name");
		
		# run the dist
		return $self->{drib}->{modules}->{Dist}->dist(basename($package),$options); 


	}
	elsif ( $options->{install} == 1 ) {

		# message created
		msg("Package Created: $name");

		# run the install
		return $self->{drib}->{modules}->{Install}->install(basename($package),$options);
		
	}
	else {
		
		# all good
		return {
    		"code" => 200,
    		"name" => $name,
    		"project" => $project,
    		"message" => "Package Created: $name"		
		};
		
	}

}