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
		
		# client
		'client' => {},
		
		# commands
		'commands' => [
			{ 
				'name' => 'dist',
				'help' => '', 
				'alias' => ['d','ds'],
				'options' => [
				]
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

    # figure our what dist package to use
    my $mod = $drib->{modules}->{Config}->get('dist') || "Drib::Dist::Local";

		# include the module
		$drib->includeModule($mod);

		# new
		$self->{client} = new $mod($drib);

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
	my @args = @{$self->{drib}->args};

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

##
## @brief dist a provided file
##
## @param $file package file
## @params $opts hashref of options
##
sub dist {

	# get 
	my ($self, $file, $opts) = @_;
	
	# branch
	my $branch = $opts->{branch} || 'current';
	
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
			"response" => "Could not find package $file to dist"	
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
				"response" => "Could not untar package file"	
			};			
		}

	my $project	= $man->{project};
	my $name	= $man->{meta}->{name};
	my $version = $man->{meta}->{version};

	if ( $self->check($project, $name, $version) ) {

		# see if they're using a file:
		if ( $man->{ov} && -e $man->{ov} && $man->{type} eq 'release' ) {

			# ask them if they want to add to the file
			my $r = ask("Version $version already exists for $pkg. Would you like to up the version and add a comment? [y]");

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
				`rm $pkg`;

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
					"response" => "Package '$pkg' version '$version' already exists"
				};
			}				

		}
		else {			
			return {
				"code" => 403,
				"response" => "Package '$pkg' version '$version' already exists"
			};
		}		

	}	

	# upload
	$r = $self->upload({
	   'project'	=> $man->{project},
	   'name'		=> $man->{meta}->{name},
	   'version'	=> $man->{meta}->{version},
	   'branch'		=> $branch,
	   'tar' 		=> $tar
    });	
    
    # name
    my $n = $man->{project}."/".$man->{meta}->{name}."-".$man->{meta}->{version};
    
    # what happened
    if ( $r ) {
    	return {
    		'code' => 200,
    		'response' => "Package $n pushed to dist"
    	};
    }
    else {
    	return {
    		'code' => 500,
    		'response' => "Unknown error prevent dist"
    	};    
    }
	

}

##
## @brief pass through to dist client
##
sub upload {
	
	# self
	my ($self, $args) = @_;

	# pass
	$self->{client}->upload($args);

}


##
## @brief pass through to dist client
##
sub check {

	# self
	my ($self, $project, $pkg, $ver) = @_;

	# pass me
	$self->{client}->check($project, $pkg, $ver);

}


##
## @brief pass through to dist client
##
sub get {

	# self
	my ($self, $project, $pkg, $ver) = @_;

	# pass me
	$self->{client}->get($project, $pkg, $ver);

}