#
#  Drib::Cmd::Cron
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package
package Drib::Cmd::Cron;

# version
our $VERSION => "1.0";

# packages we need
use File::Basename;
use File::Find;
use POSIX;
use Digest::MD5 qw(md5_hex);
use Crypt::CBC;
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
		'tmp' => $drib->{tmp},
		
		# commands
		'commands' => [
			{ 
				'name' => 'cron',
				'help' => '', 
				'alias' => [],
				'options' => [
					Switch('edit|e'),
					Switch('list|l'),
				]
			}
		]
		
	};

	# bless and return me
	bless($self); return $self;

}

##
## @brief add crons to execute
##
## @param $pid package id
## @param $crons array of crons to add
##
sub add {

	

}


##
## @brief remove crons for a package
##
## @param $pid package id
##
sub remove {


}

##
## @brief edit the crons for a pacakge
## 
## @param $pid package id
##
sub edit {


}

##
## @brief list crons for a package
##
## @param $pid package id
##
sub list {


}
