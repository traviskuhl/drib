#
#  Drib::Cmd::Command
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package
package Drib::Cmd::Command;

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

##
## @brief create a new command object
##
## @param $drib ref to the main drib
##
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
				'name' => 'command',
				'help' => '', 
				'alias' => ['cmd','start','stop','restart'],
				'options' => [
				]
			}
		]
		
	};

	# bless and return me
	bless($self); return $self;

}



##
## @brief execute a set of commands from a package
##
## @param $type type of commands to execte
## @param $pkg <mixed> either a pid or a package manifest
##
sub exec {

	# info
	my ($self, $type, $pkg) = @_;

	#  if pkg is a hash we
	unless ( ref $pkg eq 'SCALAR' ) {
		$manifest = $self->{drib}->{packages}->get($pkg);
	}
	else {
		$manifest = $pkg;
	}

	# pwd
	my $pwd = getcwd();

	# move to /
	chdir("/");

    # see if commands exists
    if ( exists $manifest->{commands} ) {
    
        # does this type of command exist
        if ( exists $manifest->{commands}->{$type} ) {
            
            # loop through and execute
            foreach my $c ( @{$manifest->{commands}->{$type}} ) {
                system($c);
            }
        
        }
    
    }
    
    # go back
    chdir($pwd);

}