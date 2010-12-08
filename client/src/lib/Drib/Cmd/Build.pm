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
use Crypt::CBC;
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
				'name' => 'build',
				'help' => '', 
				'alias' => ['bu','b'],
				'options' => [
					
				]
			},
			{
				'name' => 'build-add',
				'help' => '', 
				'alias' => ['ba'],
				'options' => [
					
				]			
			},
			{
				'name' => 'build-rm',
				'help' => '', 
				'alias' => ['br'],
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
		
	# do they want to register a build
	if ( $cmd == 'build-add' || $cmd == 'build-rm' ) {
		
		# that's simple the first command is the file they 
		# want to register, so lets save it in the list
		if ( $#args == -1 ) {
            return {
            	"code" => 404,
            	"message" => "You didn't provide a build file."
            };
		}
		
		# make sure it's a file
		unless ( -e $args[0] ) {
            return {
            	"code" => 404,
            	"message" => "You didn't provide a build file."
            };
		}		
		
		# open the file
		my $d = from_json( file_get($args[0]) );
	
		# add or remove the build
		if ( $cmd == 'build-add' ) {
	
			# add it  
			
		}
	
	}
	
	# get a list of things they want to build
	
}