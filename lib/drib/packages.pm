# drib-packages

package drib::packages;

# stuff to use
use File::Basename;
use Digest::MD5 qw(md5_hex);

# our libs
use drib::db;

# new
sub new {

    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};

    # bless me
    bless $self, $class; 

    # drib
    $self->{drib} = shift;

    # what's our var
    $self->{var} = $self->drib->path($self->{drib}->config->get("var") || "/var/drib");
    
    	# make sure our var folders exits
    	unless (-e $self->{var}) { mkdir($self->{var}); }
    	unless (-e "$self->{var}/packages/") { mkdir("$self->{var}/packages/"); }

    # load the installed packages db
    $self->{db} = new drib::db($self->{var}, "installed");

    # return
    return $self;

}

##
## @brief get the package db
##
sub db {
	my $self = shift;
	return $self->{db};
}

##
## @brief drib shortcut
##
sub drib {
	return shift->{drib};
}

##
## @brief dump shoftcut
##
sub dump {
	return shift->drib->dump(shift);
}

##
## @brief get a package id
##
sub getPid {
	my $self = shift;
	my $project = shift;
	my $name = shift;

	return md5_hex($project.$name);
}

##
## @brief isInstalled
##
sub isInstalled {
	my $self = shift;
	my $project = shift;
	my $name = shift;

	# get our pid
	my $pid = $self->getPid($project, $name);

	# packages
	my @packages = $self->db->get('packages'); 

	# see if this package is installed
	return $self->drib->in_array(\@packages, $pid);

}

##
## @brief get a package name from argv
##
sub getPidFromArg {
	my $self = shift;
	my $arg = shift;

	# parase a package name and return pid
	return $self->parsePackageName($arg)->{pid};

}

##
## @brief parse a package name
##
sub parsePackageName {
	my $self = shift;
	my $name = shift;

	# things we're going to set at some point
	my ($full, $project, $version, $pkg, $repo);

	# is there a -
	if ($name =~ /\-(current|nightly|qa|stable|[0-9\.]+$)/) {
	    # first explode for version
	    my @parts = split(/-/,$name);	
	    $version = pop(@parts);
	    $part = join("-", @parts);
	}
	else {
		$part = $name;
	}

    # now explode for the project and name
    ($project, $pkg) = split(/\//,$part);

    # does project have a : in it
    if ( index($project, ':') != -1 ) {
    	($repo, $project) = split(/\:/, $project);
    }

    # if no pkg, it must not have a project
    if ( !$pkg ) {
        $pkg = $project;
        $project = 0;
    }
    
    	if ($repo) { $full .= "$repo:"; }
    	if ($project) { $full .= "$project/"; }
    	if ($pkg) { $full .= $pkg; }
    	if ($version) { $full .= "-$version"; }
        
    # give back an object
    return { 
    	'full'		=> $full, 
    	'name'		=> $pkg, 
    	'project'	=> $project, 
    	'version'	=> $version, 
    	'pid'		=> $self->getPid($project, $pkg),
    	'repo'		=> $repo
    };


}

##
## @brief getPackage
##
sub getPackage {
	my $self = shift;
	my $project = shift;
	my $name = shift || 0;

	# get our pid
	my $pid = ($name ? $self->getPid($project, $name) : $project);

	# open our package db
	return new drib::db("$self->{var}/packages/", $pid);

}

##
## @brief update package records for installed package
##
sub installed {
	my $self = shift;
	my $opts = shift || {};

	# nicer
	my $project 	= $opts->{project};
	my $name 		= $opts->{name};
	my $version		= $opts->{version};
	my $manifest	= $opts->{manifest};

	# no raw in manifest
	delete($manifest->{raw});

	# get a pid
	my $pid = $self->getPid($project, $name);

	# get a package db
	my $db = $self->getPackage($project, $name);

	# set it's manifest
	$db->set('current', $version);
	$db->set('manifest', $manifest);
	$db->set("v$version", $manifest);
	$db->add("versions", $version);

	# save
	$db->save();

	# add to installed
	$self->db->add('packages', $pid);

	# versions
	$self->db->set($pid, $version, 'versions');

	# and done
	return $pid;

}

# i'm true
return 1;