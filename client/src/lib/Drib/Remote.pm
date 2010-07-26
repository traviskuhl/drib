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
use Net::SCP::Expect;

# drib
use Drib::Utils;

sub new {

	# get some
	my ($ref, $drib, $host, $port) = @_;

	# get myself
	my $self = {
		
		# drib
		'drib' => $drib,
		
		# host and port
		'user' => $ENV{'SUDO_USER'},
		'pass' => "",
		'host' => $host,
		'port' => $port,
			
		# connection
		'ssh' => {},
		'scp' => {},
			
	};
	
	# bless and return me
	bless($self); 	
	
	# connect
	$self->connect();	
	
	# done
	return $self;

}

# connect to dist
sub connect {
	
	# host and port
	my ($self) = @_;

	
	# !pass
	unless ( $self->{pass} ) {
		$self->{pass} = ask("Password:",1);
	}
	
	# pass
	my $pass = $self->{pass};

	# connect
	my $ssh = Net::SSH::Expect->new (
		host		=> $self->{host}, 
		port		=> $self->{port},
		password	=> $pass, 
		user		=> $self->{user}, 
		raw_pty		=> 1
	);

	# login
	my $o = $ssh->login();
              
		# bad password  
        if ($o =~ /Permission denied/) {
            fail("Incorrect Password!");
        }

	# save it 
	$self->{ssh} = $ssh;

	# connect to scp also
	$self->{scp} = new Net::SCP::Expect(host=>$self->{host}, port=>$self->{port}, 'user'=>$self->{user}, password=>$pass, auto_yes=>1, no_check=>1);
	
	# return
	return $ssh;

}

# exec
sub exec {

	# get oit 
	my ($self, $cmd) = @_;
	
	# connect
	$self->connect($host, $port);

	# run exex
	return $self->{ssh}->exec($cmd);

}

# scp
sub scp {

	# get 
	my ($self, $local, $remote) = @_;

	# do it 
	return $self->{scp}->scp($local, $remote);

}


