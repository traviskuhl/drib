#
#  drib::dist::local
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package Drib::Dist::Local;

use Drib::Utils;
use Data::Dumper;

# version
my $VERSION = "1.0";

sub new {

	# get 
	my($this, $drib, $config) = @_;

	# class
	my $class = ref($this) || $this;

	# get myself
	my $self = {
		
		# drib
		'drib' => $drib,
		
		# folder
		'folder' => $config->{folder}
	
	};
	
	# clean the folder name
	$self->{folder} = trim($self->{folder})."/";
	
	# bless and return me
	bless($self, $class); return $self;

}

sub check {

	my ($self, $project, $pkg, $ver) = @_;
	
	# make a package name
	my $name = $pkg."-".$ver.".tar.gz";

	# check if the file exists
	if ( -e $self->{folder} . "$pkg/$name" ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub get {

	my ($self, $project, $pkg, $ver) = @_;
	
	# make a package name
	my $name = $pkg."-".$ver.".tar.gz";

	# check 
	if ( !$self->check($pkg,$ver) ) {
		return 0;
	}

	# get get
	$file = file_get( $self->{folder} . "/$pkg/$name" );

}

sub upload {

	my ($self,$info) = @_;
	
	# get from info
	my $project = $info->{project};
	my $user = $info->{username};
	my $pkg = $info->{name};
	my $version = $info->{version};
	my $branch = $info->{branch};
	my $tar = $info->{tar};
	
	# package directory
	my $dir = $self->{folder} . $user . "/". $pkg . "/";
	my $name = "$pkg-$version.tar.gz";

	# see if the directory exists
	unless ( -d $dir ) {
		`sudo mkdir -p $dir`;
	} 
	
	# save this version
	file_put($dir.$name,$tar);

	# now remove the current branch version
	unlink $dir."$pkg-$branch.tar.gz";

	# set it
	file_put($dir."$pkg-$branch.tar.gz",$tar);

	# done
	return 1;

}