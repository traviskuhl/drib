#
#  Drib::Remote
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package up
package Drib::Remote;

# version number is good
my $VERSION = "1.0";

# external
use JSON;
use POSIX;
use Data::Dumper;
use Net::SSH::Expect;

# drib
use Drib::Utils;

sub new {

	# get some
	my ($ref, $drib) = @_;

	# get myself
	my $self = {
		
		# drib
		'drib' => $drib,
		
		# host and port
		'user' => $ENV{'SUDO_USER'},
		'pass' => "",
	
		# connection
		'ssh' => {}
			
	};

	
	# bless and return me
	bless($self); 	
	
	# done
	return $self;

}

# connect to dist
sub connect {
	
	# host and port
	my ($self, $host, $port) = @_;
	
		# already connected to host
		if ( exists $self->{ssh}->{$host} ) {
			return $self->{ssh}->{$host};
		}
	
	# !pass
	unless ( $self->{pass} ) {
		$self->{pass} = ask("Password:",1);
	}

	# connect
	my $ssh = Net::SSH::Expect->new (
		host		=> $self->{host}, 
		port		=> $self->{port},
		password	=> $pass, 
		user		=> $user, 
		raw_pty		=> 1
	);

	# login
	my $o = $ssh->login();
              
		# bad password  
        if ($o !~ /Welcome/) {
            fail("Incorrect Password!");
        }

	# save it 
	$self->{ssh}->{$host} = $ssh;

	# return
	return $ssh;

}

# exec
sub exec {

	# get oit 
	my ($self, $host, $port, $cmd) = @_;
	
	# connect
	$self->connect($host, $port);

	# run exex
	return $self->{ssh}->{$host}->exec($cmd);

}
