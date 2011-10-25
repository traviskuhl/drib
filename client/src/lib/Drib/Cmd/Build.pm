#
#  Drib::Cmd::Build
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# build
package Drib::Cmd::Build;

# version
our $VERSION => "1.0";

# drib
use Drib::Utils;

# packages we need
use File::Basename;
use File::Find;
use POSIX;
use Digest::MD5 qw(md5_hex);
use JSON;
use Getopt::Lucid qw( :all );
use Data::Dumper;
use File::Spec::Functions qw(:ALL);

# new 
sub new {

	# get 
	my($ref, $drib) = @_;
	
	# self
	my $self = {
		
		# drib 
		'drib' => $drib,
		
		# shortcuts
		'tmp' => $drib->{tmp},
		
		# commands
		'commands' => [
			{ 
				'name' => 'build',
				'help' => '', 
				'alias' => ['bu','b'],
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

	# args
	my @args = @{$self->{drib}->{args}};
			
	# messages
	my @msg = ();		
		
	if ( $cmd eq "build" ) {
		
		# file
		$file = shift @args;
		
			# make sure it's a file
			unless ( -e $file ) {
				return {
					"message" => "Build file not valid",
					"code" => 400
				};
			}
		
		# run each build
		push(@msg, $self->build($file, \@args, $opts)->{message});
		
	}

	# return to the parent with a general message
	return {
		'message' => join("\n", @msg),
		'code' => 0
	};			

}


##
## @brief build a given manifest
##
## @param $file build file
## @param @builds named builds to execute
## @param $opts builds options
##
sub build {

	# get manifest
	my ($self, $file, $builds, $opts) = @_;
	
	# open the build manifest and parse
	my $m = from_json( file_get($file) );
		
	# check for a build cmd
	unless ( $m->{build} ) {
		return {
			"message" => "No build instructions in $man",
			"code" => 404
		};
	}
	
	# build
	my $build = $m->{build};
	
	# where are we now
	my $pwd = getcwd();

	# check for any config settigns
	if ( $build->{_config} ) {
	
		# root
		my $resp = chdir $build->{_config}->{root} if $build->{_config}->{root};
		
			# nope
			return {"message" => "Could not move into root directory" } unless $resp;
	
	}
	
	# builds
	my %builds = %{$build};	
	
	# loop through each and build and install
	foreach my $key ( keys %builds ) {
	
		# make sure it isn't a private var
		if ( substr($key,0,1) eq "_" ) { next; }
		
		# do we have a list of builds
		if ( scalar(@{$builds}) > 0 && in_array(\@{$builds}, $key) == 0 ) { next; }
		
		# build
		$b = $builds{$key};
		
		# check for dist set
		if (exists($b->{dist})) {
			$self->{drib}->{modules}->{Dist}->do_add($b->{dist}->{name}, $b->{dist});
		}
		
		# loop through and install each package
		foreach my $pkg ( @{$b->{packages}} ) {
		
			# create a package
			if ($pkg->{do} eq "create") {			
				msg($self->{drib}->{modules}->{Create}->create($pkg->{pkg}, $pkg)->{message});
			}
			
			# install from dist
			elsif ($pkg->{do} eq "install") {
				msg($self->{drib}->{modules}->{Install}->install($pkg->{pkg}, $pkg)->{message});
			}
		
		}	
		
	}
	
}