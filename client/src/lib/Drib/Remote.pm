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
use Net::OpenSSH;

# drib
use Drib::Utils;

sub new {

	# get some
	my ($ref, $drib, $host, $port, $pword, $user, $key) = @_;

	# get myself
	my $self = {
		
		# drib
		'drib' => $drib,
		
		# host and port
		'user' => $user || $ENV{'SUDO_USER'},
		'pass' => "",
		'host' => $host,
		'port' => $port,
		'pass' => $pword || 0,
		'key'  => $key,
			
		# connection
		'_ssh' => 0,
		'_scp' => 0,
			
	};
	
	# bless and return me
	bless($self); 	
	
	# connect
	$self->connect();	
	
	# done
	return $self;

}

sub DESTROY {

	# who am i
	my $self = shift;
	
	# close 
	$self->exec("exit;");
	
}

# connect to dist
sub connect {
	
	# host and port
	my ($self) = @_;

	if ( $self->{_ssh} ) { return; }
	
	# opts
	my %opts = (
		host => $self->{host},
		user => $self->{user},
		port => $self->{port},
		strict_mode => 0,
		master_stdout_discard => 1,
		master_opts => [-o => "StrictHostKeyChecking no"]
	);	
		
	# ssh 	
	my $ssh = 0;
	
	# if we have a key
	# do it that way
	if ($self->{key}) {
	
		# key
		$opts{'key_path'} = $self->{key};

		# ssh 
		$ssh = Net::OpenSSH->new(%opts);

		# error or end
		if ( $ssh->error ) { 
			$ssh = 0;
		}
	
	}
	
	# if we don't have a key try the password
	else {
	
		# password
		$opts{'password'} = $self->{pass};
			
		# try password again
		for ( my $i = 0; $i < 3; $i++ ) {
	
			# !pass
			unless ( $self->{pass} ) {
				$self->{pass} = ask("Password:",1);
			}
			
			# set it 
			$opts{'password'} = $self->{pass};
			
			# ssh 
			$ssh = Net::OpenSSH->new(%opts);
	
			# error or end
			if ( $ssh->error ) { 
				$ssh = 0; $self->{pass} = 0; next;
			}
			else {
				break;
			}
	
		}
		
	}

	# no ssh
	if ( $ssh == 0 ) { fail("Incorrect Password or Key"); }

	# save it 
	$self->{_ssh} = $ssh;

	# return
	return $ssh;

}

# exec
sub exec {

	# get oit 
	my ($self, $cmd) = @_;	

	# are they trying to run sudo
	if ( $cmd =~ /^sudo/i ) {
			
		# send to sudo
		my ( $pty, $pid ) = $self->{_ssh}->open2pty({stderr_to_stdout => 1},"sudo -k; " .$cmd) or return "failed to attempt sudo bash: $!\n";
	
		# expect
		my $e = Expect->init($pty);	
		
		# all raw
		$e->raw_pty(1);
			
		# password?
		my @r1 = $e->expect(1, ":", "-re", "/password/i") or "expect fail";
	
			# send password
			$e->send($self->{pass}."\n");	
			
		# password is good
		my @r = $e->expect(10, "#", "-re", "/.*#\s+/") or fail("Bad Password");
	
			# another password
			if ( $r[3] =~ /password/i ) {
			
				# send 
				$e->send($self->{pass}."\n");

				# resp
				@r = $e->expect(10, "#", "-re", "/.*#\s+/") or fail("Bad Password");
		
			}
	
	 	# done
	 	$e->hard_close();
	 	
	 	# close it
	 	close $pty;

		# done
		return wslb_trim(($r[3] ne "" ? $r[3] : $r[1]));

	}
	else {
		my($out, $err) = $self->{_ssh}->capture2($cmd);
		return wslb_trim(($out ne "" ? $out : $err));
	}

}

# test
sub test {

	# get oit 
	my ($self, $cmd) = @_;	

	# run exex
	return $self->{_ssh}->test($cmd);

}

# scp
sub scp {

	# get 
	my ($self, $local, $remote) = @_;

	# do it 
	return $self->{_ssh}->scp_put({stderr_discard=>1}, $local, $remote);

}

sub scp_get {

	# get 
	my ($self, $remote, $local) = @_;

	# do it 
	return $self->{_ssh}->scp_get($remote, $local);

}


