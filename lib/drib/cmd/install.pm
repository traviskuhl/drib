# drib-install.pm

package drib::cmd::install;

# base me
use base qw/drib::cmd/;

# use
use POSIX;
use File::Basename;
use JSON;
use File::Copy;


##
## @brief create 
##
sub new {

    # make me
    my $self = shift;
    
    # super new
    $self->SUPER::new(shift); 
    
    # desc
    $self->{'desc'} = "Install a package";

    # define myself... i feel fat
    $self->{'cmds'} = {
    
        # !default
        'default' => {
            'sub' => 'cmd_install',
            'name' => 'install',
            'args' => [],
            'opts' => [
            	"project|p=s",            	
            	"version|v=s",
            	"branch|b=s",
            	"cleanup|c",
            	"same|s",
            	"downgrade|d",
            	"repo|r"
            ],
            'desc' => "Install a package",
            'alias' => ['i']
        },
       
    };

    # me
    return $self;    

}

##
## @brief handle run command for install
##
sub cmd_install {
	my $self = shift;
	my $opts = shift || {};

	# msg
	my @msg = ();

	# get each file
	foreach my $file (@{$self->drib->{argv}}) {

		# set the file
		$opts->{file} = $file;

		# do it 
		push(@msg, $self->install($opts)->{message});

	}

	# message
	$self->message(@msg);

}


##
## @brief install a package file
##
sub install {
	my $self = shift;
	my $opts = shift || {};

	# something easier
	my $file 		= $opts->{file};
	my $name 		= $opts->{name};
	my $project 	= $opts->{project};
	my $branch 		= $opts->{branch} || 'current';
	my $version 	= $opts->{version} || $branch;
	my $cleanup 	= $opts->{cleanup} || 0;
	my $same 		= $opts->{same} || 0;
	my $downgrade	= $opts->{downgrade} || 0;
	my $repo		= $opts->{repo};

	# pwd
	my $pwd = getcwd();

	# make our tmp
	my $tmp = $self->drib->{tmp}."/".time(); mkdir($tmp);	

	$self->log("using tmp $tmp");

	# see if there's a file
	unless ($file) {

	}

	# make sure we have a file
	unless (-e $file) {
		return {
			"message" => "Unable to open package file '$file'",
			"code" => 404
		};
	}

	$self->log("found package file '$file'");

	# filename
	my $filename = basename($file);
	
	# move our file into tmp
	copy($file, "$tmp/$filename");

	# move into tmp
	chdir($tmp);

	# untar it
	my $r = Archive::Tar->extract_archive($filename, COMPRESS_GZIP);

	# nope
	unless ($r || -e "./.manifest") {
		return {
			"message" => "Unable to unpack package file '$filename'",
			"code" => 500
		};
	}

	$self->log(" unpacked package file");

	# open up the manifest
	my $manifest = from_json($self->drib->file_get("./.manifest"));

	# no manifest is bad
	unless(ref $manifest eq "HASH") {
		return {
			"message" => "Unable to parse package manifest",
			"code" => 500
		}
	}

	# reset waht the manifest says
	$name = $manifest->{name};
	$project = $manifest->{project};
	$version = $manifest->{version};

	# foud
	$self->log(" found manifest for $project/$name-$version");	

	# figure out if this package is installed
	my $packageDb = $self->drib->packages->getPackage($project, $name);

	# what's currently installed
	my $current = $packageDb->get('current') || 0;

	# log
	$self->log(" installed version is '$current'");

		# is it the same
		if ($current && $current eq $version && $same != 1 ) {
			return {
				"message" => "$project/$name-$version is already installed",
				"code" => 409
			}
		}

		# is this a downgrade
		if ($current && $self->drib->versioncmp($version, $current) == -1 && $downgrade != 1) {
			return {
				"message" => "$project/$name-$version is less than the installed version $current",
				"code" => 409
			}
		}

	# ok so we're good to install
	# this package thing. so lets open
	# the dir and move this shit
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

	# ok it's installed, tell the package dir
	my $pid = $self->drib->packages->installed({
		'project' => $project, 
		'name' => $name, 
		'version' => $version,
		'manifest' => $manifest
	});

	# ok we need to update the settings
	$self->drib->cmd('settings')->set($pid, $manifest->{set});

	# and the settings files
	$self->drib->cmd('settings')->files($pid, $manifest->{set_files});

	# and the cron stuff
#	$self->drib->cmd('cron')->add($pid, $manifest->{crons});

	# mvoe back
	chdir($pwd);

	# cleanup
	if ($cleanup == 1) {
		`sudo rm -f $pwd/$file`;
	}

	# and DONE!
	return {
		"message" => "Package $project/$name-$version installed!",
		"code" => 200
	};

}

# i'm true
return 1;