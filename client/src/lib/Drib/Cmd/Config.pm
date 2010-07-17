#
#  Drib::Cmd::Config
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package our config
package Drib::Cmd::Config;

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
		'db' => new Drib::Db('config',$drib->{var}),	# load the db
		
		# commands
		'commands' => [
			{ 
				'name' => 'config',
				'help' => '', 
				'alias' => [],
				'options' => [
					Switch('unset|u')
				]
			}
		]
		
	};

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
	my ($self, $cmd, $opts, @args) = @_;
	
	
}
