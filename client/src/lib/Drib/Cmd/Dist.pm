#
#  Drib::Cmd::Dist
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package our dist
package Drib::Cmd::Dist;

# version
our $VERSION => "1.0";

# packages we need
use Digest::MD5 qw(md5_hex);
use JSON;
use Getopt::Lucid qw( :all );
use Data::Dumper;
use POSIX;
use Config;

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
		'tmp' => $drib->{tmp},				# tmp folder name
		
		# db shortcut
		'db' => new Drib::Db('dist', $drib->{var}),		
		
		# default dist
		'default' => $drib->{modules}->{Config}->get('default-dist'),
		
		# client
		'clients' => {},
		
		# commands
		'commands' => [
			{ 
				'name' => 'dist',
				'help' => '', 
				'alias' => ['d','ds'],
				'options' => [
					Param('repo|r')
				]
			},
			{
				'name' => 'repo',
				'help' => '',
				'alias' => [],
				'options' => []			
			},			
			{
				'name' => 'add-repo',
				'help' => '',
				'alias' => [],
				'options' => [				
				]			
			},
			{
				'name' => 'ls-repo',
				'help' => '',
				'alias' => [],
				'options' => []			
			},
			{ 
				'name' => 'search',
				'help' => '', 
				'alias' => ['s','sr'],
				'options' => [
				]
			}			
		]
		
	};
	
	# check to see if we have our
	# self repo
	unless ( $self->{db}->get('self') ) {
		$self->{db}->set('self',{
			"name" => "self",
			"class" => "Drib::Dist::Public",
			"base" => "http://drib-pdm.org/download/pkg/",
			"path" => "%name-%version.tar.gz"
		});
	}
	
	# we want to be backwards compatable
	# so we should check config for dist-remote-* and 
	# map that over as defaut
	if ( $self->{drib}->{modules}->{Config}->get("dist") ) {
		
		# config shortcut
		my $c = $self->{drib}->{modules}->{Config};
		
		# get it 
		my $d = $c->get("dist");		
	
		# map it over
		if ( $d eq "Drib::Dist::Remote" ) {
		
			# set default
			$self->{db}->set('default',{
				"name" => "default",
				"class" => $d,
				"host" => $c->get("dist-remote-host"),
				"port" => $c->get("dist-remote-port"),
				"folder" => $c->get("dist-remote-folder")
			});			
			
			# unset some stuff
			$c->unset(["dist", "dist-remote-host", "dist-remote-port", "dist-remote-folder"]);
			
		}
	
	}

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
	
	# args
	my @args = @{$self->{drib}->{args}};

		# things to watch for arg1
		my @a1 = ('add', 'ls', 'rm', 'list');
			
			# check me out
			if ( scalar @args > 0 && in_array(\@a1, $args[0]) ) {
				$cmd = (shift @args)."-repo";
			}

	# add a dist
	if ( $cmd eq "add-repo" ) {
	
		# just run add dist
		return $self->add();
	
	}
	elsif ( $cmd eq "ls-repo" || $cmd eq "list-repo" ) {
		
		# all
		my %all = %{$self->{db}->all()};
		
		# add a manifest
		foreach my $item ( keys %all ) {
			if ( $all{$item} ) {
				msg(" $item");			
			}
		}
	
		exit();
	
	}
	elsif ( $cmd eq "repo" ) {
	
		# get the repo
		my $repo = $self->{db}->get( (shift @args) );
	
			# needs to exists
			unless ( $repo ) {
				return {
					'code' => 404,
					'message' => "Could no find repo $repo"
				};
			}
	
		# loop and show
		foreach my $key ( keys %{$repo} ) {
			msg(" $key: $repo->{$key}");
		}
	
		# done
		exit();
	
	}
	else {
	
		# no args?
		if ( scalar @args == 0 ) {
			return {
				'code' => 404,
				'message' => "No package files given to push"
			}
		}
	
		# foreach args go ahead and push
		foreach my $file (@args) {
	
			# msg
			my @msg = ();
		
			# do it
			push(@msg, $self->dist($file, $opts)->{message});
		
			# return to the parent with a general message
			return {
				'message' => join("\n",@msg),
				'code' => 0
			};
					
		}

	}
	
}

##
## @brief dist a provided file
##
## @param $file package file
## @params $opts hashref of options
##
sub dist {

	# get 
	my ($self, $file, $opts) = @_;
	
	# no tar.gz on package name
	unless ( $file =~ /\.tar\.gz/ ) {
		$file .= ".tar.gz";
	}

	# pwd
	my $pwd = getcwd();

	# need package
	unless ( -e $file ) {
		return {
			"code" => 404,
			"message" => "Could not find package $file to dist"	
		};
	}

	# file
	my $tar = file_get($file);

	# unpack the package file
	my $r = $self->{drib}->unpackPackageFile( $tar );

	# manifest
	my $man = $r->{manifest};
	my $tmp = $r->{tmp};

		# could not tar
		unless ( $man ) {
			return {
				"code" => 400,
				"message" => "Could not untar package file"	
			};			
		}	
		
	# tell them what's up
	msg("Preparing Dist Process:");
	
	# repo
	my $repo = $opts->{repo};
	
		# unless given a repo
		unless ( $repo ) {
		
			# get all repos
			my @repos = keys %{$self->{db}->all()};
						
			# target 
			msg(" Available Repositories:");
			
			# default
			my $d = 0;
			
			# give them optios
			for ( $i = 0; $i <= length(@repos); $i++ ) {
			
				# is it the default
				$d = $i if ( $repos[$i] eq $self->{default} );
			
				# msg 
				msg("   [$i] ".$repos[$i]);
				
			}
			
			# ask
			my $r = ask(" Select a Repository [$d]:");
		
			# set it 
			$repo = $repos[$r];
			
		}
		
	# connect to our repo
	my $dist = $self->init($repo);		
	
		# has code
		if ( defined $dist->{code} ) {
			fail("Could not connect to dist module");
		}
			
	# branch
	my $branch = $opts->{branch} || 'current';
	
		# ask about branch
		$branch = ask(" Branch [$branch]:");	
	
	my $project	= $man->{project};
	my $name	= $man->{meta}->{name};
	my $version = $man->{meta}->{version};

	if ( $dist->check($project, $name, $version) ) {

		# see if they're using a file:
		if ( $man->{ov} && -e $man->{ov} && $man->{type} eq 'release' ) {

			# ask them if they want to add to the file
			my $r = ask("Version $version already exists for $name. Would you like to up the version and add a comment? [y]");

			# if we get y
			if ( lc(substr($r,0,1)) eq "y" || $r eq "" ) {

				# one more
				my $iv = incr_version($version);

				# ask for the new version
				my $v = ask(" New version Number [".$iv."]:");

					# no number
					if ( $v eq "" ) {
						$v = $iv;
					}

				# comment
				my $c = ask(" Add Comments [n]:");

					if ( lc(substr($r,0,1)) eq "y" ) {

						# tmp file
						my $t = $TMP . "/" . rand_str(10);

						# launch
						system("vi $t");

						# get it 
						$c = file_get($t);

						# remove
						`rm $t`;

					}

				# append our new stuff
				my $nf = "Version $v\n$c\n\n".$man->{changelog};

				# save it 
				file_put("$tmp/changelog",$nf);	# to package
				file_put($man->{ov},$nf); # to vhangelog file

				# done
				# set the new version number
				$version = $man->{meta}->{version} = $v;

				# resave the manifest	
				file_put($tmp."/.manifest", to_json($man) );

				# pwd
				my $pwd = getcwd();

				# move into tmp
				chdir($tmp);

				# remove the tar
				`rm $file`;

				# repackage the tmp dir 			
				`sudo tar -czf $name.tar.gz .`;

				# package
				$file = file_get($tmp."/$name.tar.gz");

				# move back
				chdir($pwd);

			}
			else {			
				return {
					"code" => 403,
					"message" => "Package '$pkg' version '$version' already exists"
				};
			}				

		}
		else {			
			return {
				"code" => 403,
				"message" => "Package '$pkg' version '$version' already exists"
			};
		}		

	}	

	# upload
	$r = $dist->upload({
	   'project'	=> $man->{project},
	   'name'		=> $man->{meta}->{name},
	   'version'	=> $man->{meta}->{version},
	   'branch'		=> $branch,
	   'tar' 		=> $tar
    });	
    
    # name
    my $n = $man->{project}."/".$man->{meta}->{name}."-".$man->{meta}->{version};
    
	# move back
	chdir($pwd);    
    
    # what happened
    if ( $r ) {
    	return {
    		'code' => 200,
    		'message' => "Package $n pushed to dist"
    	};
    }
    else {
    	return {
    		'code' => 500,
    		'message' => "Unknown error prevent dist"
    	};    
    }
	

}

##
## @brief add a new dist server
##
sub add {

	# self
	my ($self) = @_;

	# questions
	my %types = (
		"local" => {
			"class" => "Drib::Dist::Local",
		 	"questions" => [
				{"text" => "Local Folder Path:", "var" => "folder"}				
			],
		},
		"remote" => {
			"class" => "Drib::Dist::Remote",		
		 	"questions" => [
				{"text" => "Remote Host:", "var" => "host"},
				{"text" => "Remote Port:", "var" => "port"},
				{"text" => "Remote Folder Path:", "var" => "folder"},			
			],
		},
		"public" => {
			"class" => "Drib::Dist::Public",		
		 	"questions" => [
				{"text" => "Base Url:", "var" => "base"},
				{"text" => "Folder Path Syntax [%project/%name-%version.tar]:", "var" => "path", "default" => "%project/%name-%version.tar.gz"},
			],
		}
	);
	
	my @types = keys %types;

	# cofnig
	my $config = {};

	# figure out what type
	my $type = ask(" What type of dist server [".join(", ", @types)."]:");
	
		# not a good type
		unless ( in_array(\@types, $type) ) {
			return {
				'message' => "Unknown dist type",
				'code' => 400
			};
		}

	# name the dist
	my $name = ask(" Name of this dist [default]:");

		# name it default
		if ( $name eq "" ){ $name = "default"; }

		# check if it's taken
		if ( $self->{db}->get($name) ) {
			return {
				"message" => "Dist name $name already in use",
				"code" => 400
			};
		}

	# add it 
	$config->{name} = $name;

	# now loop throug hthe quests
	foreach my $q ( @{$types{$type}->{questions}} ) {
		
		# ask them and  set the variable in config
		$config->{$q->{var}} = ask(" ".$q->{text});
	
		# if it's blank and there's a default
		if ( $config->{$q->{var}} eq "" && exists $q->{default} ) {
			$config->{$q->{var}} = $q->{default};
		}
	
	}

	# default
	my $deafult = ask(" Make this your default dist [y]:");

	# is it the default
	if ( $default eq "" || substr($default, 0, 1) eq "y" ) {
		$self->{drib}->{modules}->{Config}->set('default-dist', $name),
	}
	
	# set our class
	$config->{class} = $types{$type}->{class};

	# save this dist
	$self->{db}->set($name, $config);

	# all good return a thank you
	return {
		"message" => "Dist Added",
		"code" => 200
	};

}

##
## @brief connect to our rep
##
sub init {
	
	# self
	my ($self, $name) = @_;	

	# make sure it's a good reo
	my $repo = $self->{db}->get($name);

		# nope
		unless ( $repo ) {
			return {
				"code" => 404
			};
		}
		
	# mod
	my $mod = $repo->{class};

	# include the module
	$self->{drib}->includeModule( $mod );

	# new
	$self->{clients}->{$name} = $mod->new($self->{drib}, $repo);
	
	# give it back just in case
	return $self->{clients}->{$name};

}


##
## @brief pass through to dist client
##
sub upload {
	
	# self
	my ($self, $name, $args) = @_;
		
		# make sure it's connected
		unless ( defined $self->{clients}->{$name} ) {
			$self->init($name);
		}

	# pass
	$self->{clients}->{$name}->upload($args);

}


##
## @brief pass through to dist client
##
sub check {

	# self
	my ($self, $name, $project, $pkg, $ver) = @_;

		# make sure it's connected
		unless ( defined $self->{clients}->{$name} ) {
			$self->init($name);
		}

	# pass me
	return $self->{clients}->{$name}->check($project, $pkg, $ver);

}


##
## @brief pass through to dist client
##
sub get {

	# self
	my ($self, $name, $project, $pkg, $ver) = @_;

		# make sure it's connected
		unless ( defined $self->{clients}->{$name} ) {
			$self->init($name);
		}

	# pass me
	return $self->{clients}->{$name}->get($project, $pkg, $ver);

}