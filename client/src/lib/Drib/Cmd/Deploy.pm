#
#  Drib::Cmd::Deploy
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# build
package Drib::Cmd::Deploy;

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
				'name' => 'deply',
				'help' => '', 
				'alias' => ['de'],
				'options' => [
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
		push(@msg, $self->deploy($file, \@args, $opts)->{message});
		
	}

	# return to the parent with a general message
	return {
		'message' => join("\n", @msg),
		'code' => 0
	};		
	
}


##
## @brief deploy a given build
##
## @param $file build file
## @param $targets named targets to execute
## @param $opts builds options
##
sub deploy {

	# get manifest
	my ($self, $file, $targets, $opts) = @_;
	
	# open the build manifest and parse
	my $m = from_json( file_get($file) );
		
	# check for a build cmd
	unless ( $m->{deploy} ) {
		return {
			"message" => "No deploy instructions in $man",
			"code" => 404
		};
	}
	
	# build
	my $deploy = $m->{deploy};
	
	# make sure the targets they listed 
	# are really good targets and that
	# there's at least one
	if ( scalar(@{$targets}) == 0 ) {
		return {
			"message" => "No targets given",
			"code" => 400
		};
	}
	
}
