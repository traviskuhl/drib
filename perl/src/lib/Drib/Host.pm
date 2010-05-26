#
#  drib::host
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package up
package drib::host;

# version number is good
my $VERSION = "0.0.1";

# external
use JSON;
use POSIX;
use Data::Dumper;
use Net::SSH::Perl;
use Net::SSH::Perl::Constants qw( :msg );


# drib
use drib::utils;

sub new {

	# get some
	my ($ref,$host,$pass) = @_;

	# get myself
	my $self = {};

	# split on :
	($host,$port) = split(/:/,$host);

	$self->{host} = $host;
	$self->{port} = $port || 22;
	$self->{pass} = $pass;
	
	# bless and return me
	bless($self); 
	
	# connect
	$self->connect();	
	
	# done
	return $self;

}

# connect to dist
sub connect {

	# vars
	my $self = shift;
	
	# username
	my $user = $ENV{'SUDO_USER'};	

	# ssh 
	$self->{ssh} = Net::SSH::Perl->new($self->{host}, port => $self->{port}, protocol => 2, debug => 0, interactive => 0 );

	# pword
	my $pword;

	# password
	if ( $self->{pass} ) {
		$pword = $self->{pass};
	}
	else {
		$pword = ask("Password:",1);				
	}
	
	# lojgn
	$self->{ssh}->login($user,$pword);
	
	# handler
	$self->{ssh}->register_handler('stderr', sub {	
        my($channel, $buffer) = @_;
        
        # if password send it
      	$channel->send_data($pword."\n");
        
    });	
	
	# make sure drib is installed
	my $cmd = "sudo drib";
	
	# test that drib is installed
	my($stdout, $stderr, $exit) = $self->{ssh}->cmd($cmd);

	# make sure it's there
	if ( $stderr && $stderr =~ /command not found/ ) {
		fail("Drib is not installed on $self->{host}:$self->{port}");
	}

}

sub cmd {

	my $self = shift;
	my $cmd = shift;

	# run 
	my($stdout, $stderr, $exit) = $self->{ssh}->cmd($cmd);	

	# result
	my $r = ($stderr?0:1);
	my $msg = ($stderr?$stderr:$stdout);
	
	# what happened
	return ($r, $msg);

}
