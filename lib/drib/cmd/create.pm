# drib-create

package drib::cmd::create;

# use our base cmd
use base qw/drib::cmd/;

# use
use POSIX;
use File::Basename;
use File::Find;
use File::Spec;
use Cwd;
use Archive::Tar;

##
## @brief create 
##
sub new {

    # make me
    my $self = shift;
    
    # super new
    $self->SUPER::new(shift); 
    
    # desc
    $self->{'desc'} = "Create a package";

    # define myself... i feel fat
    $self->{'cmds'} = {
    
        # !default
        'default' => {
            'sub' => 'cmd_create',
            'name' => 'create',
            'args' => [],
            'opts' => [
            	"install|i",
            	"dist|d=s",
            	"cleanup|c",
                "type|t",
            	"var=s"
            ],
            'desc' => "Create a package",
            'alias' => ['c']
        },
       
    };

    # me
    return $self;    

}


##
## @brief create a packge 
##
sub cmd_create {
	my $self = shift;
	my $opts = shift || {};

	# file
	$opts->{file} = \@ARGV;

	# pwd
	my $pwd = getcwd();

	# figure out if we have any package in this folder
	if (scalar @{$opts->{file}} == 0) {

		# first see if there are any files 
		# that match our parser ext
		$opts->{file} = $self->drib->util->getParsableFiles($pwd);

	}

	# no files
	if (scalar @{$opts->{file}} == 0) {
		$self->message("No package files found"); return;
	}

	# msg
	my @msg = ();

	# run the create
	foreach my $file (@{$opts->{file}}) {

		# set file in opts
		$opts->{file} = File::Spec->rel2abs($file);

		# execute
		push(@msg, $self->create($opts)->{message});

	}

	# message
	$self->message(@msg);

}

##
## @brief create a package
##
sub create {
	my $self = shift;
	my $opts = shift || {};

	# make our opts a little easier to use
	my $file = $opts->{file};
	my $dist = $opts->{dist} || 0;
	my $install = $opts->{install} || 0;
	my $cleanup = $opts->{cleanup} || 0;
    my $type = $opts->{type} || "release";
	my @vars = $opts->{vars} || ();
	my $vars = {};

    # some things we'll set 
    my $branch = "release";

    # make sure we have a file
    if ($file eq "") {
        return {
            'message' => "Unable to open file $file",
            'error' => 404
        }            
    }

    $self->log("found manifest file '$file'");

	# lets conver our vars
	foreach my $v (@vars) {
		my ($name, $val) = split(/\=/, $v);
		$vars->{$name} = $val;
	}

	# no file or doesn't exist we stop
	unless (-e $file) {
		return {
			'message' => "Unable to open file $file",
			'error' => 404
		}
	}

	# where are we now
	my $pwd = getcwd();

	# get some info about our file
	my ($name, $path) = fileparse($file);

	# move into the folder of the build file
	chdir($path);

	# open the manifest
	my $manifest = $self->drib->util->parseFile($file, $vars);

    # no manifest
    if (ref($manfiest) != "HASH") {
        return {
            "message" => "Unable to parse package manifest",
            "code" => 400
        };
    }

    # meta shortcut
    my $meta = $manifest->{meta};

    $self->log("parsed manfiest file");

    # lets get a version
    my $version = $manifest->{meta}->{version};

        # is it a file we need to look in
        if ($version =~ /file\:(.*)/){       

            # open the file 
            my $f = $self->drib->file_get($1) =~ /Version ([0-9\.]+)/i;

            # version
            $version = $1;

        }

    # no version
    unless ($version) {
        return {
            "message" => "No version given",
            "code" => 400
        };
    }

    # version
    if ( $type eq "symlink" || $type eq "s" ) {
        $version = "$version.S".time();        
        $dist = 0;
    }
    elsif ( $type eq "beta" || $type eq "b" ) {
        $version = "$version.B".time();
        $branch = "beta";            
    }
    elsif ( $type eq "nightly" || $type eq 't' ) {
        $version = "$version.N".time();    
        $branch = "nightly";            
    }
    elsif ( $type eq "qa" || $type eq 'q' ) {
        $version = "$version.QA".time();    
        $branch = "qa";            
    }

    $self->log(" found version '$version' and branch '$branch'");

    # create our tmp directory 
    my $tmp = $self->drib->{tmp} . "/" . $version; mkdir($tmp);

    # files
    my @dirs = ();

    # if we have directories, let's make them
    foreach my $dir (@{$manifest->{dirs}})  {

        # the directory
        my $d = $self->path([$tmp, $dir->{dir}]);

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

        # log
        $self->log("  added folder '$dir->{dir} to package");

        # add listing
        push(@dirs,$d);

    }

    # files & settings
    my @files = (), @settings = ();    

    # loop through files
    foreach my $file (@{$manifest->{files}}) {

        # get the dir 
        $dest = $self->path([$tmp, $file->[0]]);

        # make 
        unless (-e $dest) {
            `sudo mkdir -p $dest`;
            push(@dirs, $dest);
        }

        # now find each for the files
        my @_files = ();

        # make sure we have a src
        unless (ref $file->[1] eq "HASH") {
            $file->[1] = {"src" => $file->[1]};
        }

        # file
        my $_file = $file->[1];
    

        # if it's a src, there's only one file to ad
        if (defined $_file->{src}) {
            push(@_files, $_file);
            $self->log("  found file '$_file->{src}'");
        }

        # is it a find command
        elsif (defined $_file->{find}) {

            # dest has one too many roots
            $dest = dirname($dest)."/";

            # loc
            $self->log("  running find command '$_file->{find}'");

            # run our file
            my $lines = `sudo find $_file->{find}`;

            # eacg
            foreach my $line (split(/\n/, $lines)) {
                chomp($line);
                push(@_files, {
                    'src'   => $line,
                    'user'  => $_file->{user},
                    'group' => $_file->{group},
                    'mode'  => $_file->{mode},
                    'settings' => $_file->{settings}
                });                
            }

        }

        if (scalar @_files == 0) {
            $self->log("  no files found. moving to next");
            next;
        }

        # loop through each of the found files
        foreach my $item (@_files) {

            # not a file
            unless (-f $item->{src}) {
                next;
            }

            # maintain root
            if ($item->{src} eq "/") {
                $self->log("  ignoring file '/' as root"); next;
            }

            # get src parts
            my @parts = split(/\//, $self->drib->slash_trim($item->{src}));
            my $f = shift(@parts);
            my $root = Cwd::realpath(substr($f,0,1) eq '.' ? $f."/".shift(@parts) : "./$f");

            # get our real file path
            my $filepath = Cwd::realpath($item->{src});

            # we need to remove the root
            $filepath =~ s/$root//i;

            # dest 
            my $d = $dest.$self->drib->slash_trim($filepath);

            # add it 
            $self->log("  adding file '$filepath' to manifest");

            # push to files
            push(@files, $d);

            # is it a settings file
            my $isSetting = 0;

            # is it a settings file
            if (defined $item->{settings} && $item->{settings} eq "true") {
                push(@settings, {
                    "file" => $d,
                    "tmpl" => $self->drib->file_get($item->{src})
                });
                $self->log("  adding settings file '$filepath'");
                $isSetting = 1;
            }

            # move the files into the correct place
            if (($type eq 'symlink' || $type eq "s") && $isSetting != 1) {
                my $src = $self->drib->path([getcwd, $item->{src}]);
                symlink $src, $d;
            }
            else {
                `sudo cp -f $item->{src} $d`;
            }

            # if user
            if ( defined $item->{user} ) {
                `sudo chown $item->{user} $d`;
            }

            # group
            if ( defined $item->{group} ) {
                `sudo chown :$item->{group} $d`;
            }

            # mode
            if ( defined $item->{mode} ) {
                `sudo chmod $item->{mode} $d`;
            }

            # rename
            if ( defined $item->{rename} ) {
                `sudo mv $d $dest$item->{rename}`;
            }

        }

    }

    # move into our tmp dir
    chdir($tmp);

    # changelog
    my $changelog = (defined $manifest->{meta}->{changelog} ? $self->drib->file_get($manifest->{meta}->{changelog}) : "" );
        
    # make our manifest
    my $buildManifest = {
        'type' => $type,
        'project' => $meta->{project},
        'name' => $meta->{name},
        'meta' => $meta,
        'set' => $meta->{set},
        'set_files' => \@settings,
        'crons' => $meta->{cron},
        'commands' => $meta->{commands},
        'raw' => $manifest,
        'changelog' => $changelog,
        'depend' => $meta->{depend},
        'buildenv' => {
            'user' => $self->drib->{user},
            'host' => $ENV{'HOSTNAME'},
            'pwd' => $ENV{'PWD'}
        },
        'files' => map { s/$tmp//g; $_; } @files
    };

    # put our manifest into the file
    $self->drib->file_put("./.manifest", to_json(buildManifest));

    # name our package
    my $name = "$pkg/$version"; my $tar = $name.".tar.gz";

    # tar it up
    Archive::Tar->create_archive( $tar, COMPRESS_GZIP, [$tmp] );

    # make sure out tar is cool
    unless ( -e $tar) {
        return {
            "message" => "Unable to build package tar",
            "code" => 500
        }
    }

}

return 1;