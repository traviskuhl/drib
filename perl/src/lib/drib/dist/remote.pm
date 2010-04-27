#
#  drib::dist::remote
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package drib::dist::remote;

use drib::utils;
use Data::Dumper;
use Net::SFTP::Foreign;

# version
my $VERSION = "0.0.1";

sub new {

	# get some
	my ($ref,$config) = @_;

	# get myself
	my $self = {};
	
	# get
	$self->{isConnected} = 0;	
	$self->{config} = $config;
	
	# stuff
	$self->{server} = $config->get("dist-remote-server");
	$self->{port} = $config->get("dist-remote-port");
	$self->{folder} = trim($config->get("dist-remote-folder"))."/";
	
	# if no
	unless ( $self->{server} && $self->{port} && $self->{folder} ) {
		fail("You need to define server, port & folder:\n drib config dist-remote-server=<server>\n drib config dist-remote-port=<port>\n drib config dist-remote-folder=<folder>");
	}
	
	# bless and return me
	bless($self); return $self;

}

# connect to dist
sub connect {

	# vars
	my $self = shift;
	
	# username
	my $user = $ENV{'SUDO_USER'};	
	
	# already connected we can skip
	if ( $self->{isConnected} == 1 ) {

		# ssh 
		$self->{ssh} = new Net::SFTP::Foreign($self->{server}, user=>$user, password=>$self->{pass}, port=>$self->{port}, autodisconnect=>0, timeout=>5);
		
		# done
		return;

	}
	
	# connect
	my $ssh = 0;
	
	# tries
	my $max = 3;
	my $tries = 0;
	$self->{pass} = 0;

	# max
	while ( $tries < $max ) {
		
		# password
		my $pword = ask("Password:",1);				
		
		# ssh 
		$self->{ssh} = new Net::SFTP::Foreign($self->{server}, user=>$user, password=>$pword, port=>$self->{port}, autodisconnect=>0, timeout=>5);
		
		# worked
		unless ( $self->{ssh}->error ) {
			
			# set it 
			$self->{isConnected} = 1;
			$self->{pass} = $pword;
			
			#done
			return;
			
		}
		else {
			print $self->{ssh}->error;
		}
					
	}	

}


sub check {

	# check
	my ($self,$project,$pkg,$ver) = @_;
	
	# connect    
    $self->connect();	
	
	# try to stat the file
	my $file = $self->{folder} . $project."/".$pkg."/".$pkg."-".$ver.".tar.gz";

	# return 
	my $r = 0;

	if ( $self->{ssh}->stat($file) ) {
		$r = 1;
	}
	
	$self->{ssh}->disconnect();

	# what 
	return $r;

}

sub get {

	my ($self,$project,$pkg,$ver) = @_;
	
	# connect    
    $self->connect();	
	
	# try to stat the file
	my $file = $self->{folder} . $project."/".$pkg."/".$pkg."-".$ver.".tar.gz";

	# give back
	my $tar = $self->{ssh}->get_content($file);
		
	$self->{ssh}->disconnect();	
	
	# return
	return $tar;	
	
}

sub upload {

    # do it 
    my ($self,$args) = @_;

	# connect    
    $self->connect();

    # project
	my $project = $args->{project};
	my $user = $args->{username};
	my $pkg = $args->{name};
	my $version = $args->{version};
	my $branch = $args->{branch};
	my $tar = $args->{tar};
	
	# package folder
	my $folder = $self->{folder} . $project . "/" . $pkg;
	
		my $a = Net::SFTP::Foreign::Attributes->new();
			$a->set_perm(0777);
	
		# does a folder exist 
		unless ( $self->{ssh}->stat($folder) ) {
			$self->{ssh}->mkpath($folder, $a);
		}
		
			
	# tmp
	my $tmp = $self->{config}->get('tmpf') . "/" . rand_str(10);			
	
	# save it 
	file_put($tmp,$tar);
			
	# put the filder
	$self->{ssh}->put($tmp, $folder . "/" . $pkg . "-" . $version . ".tar.gz", perm=>0777 );			
				
	# bracnh fiuel
	$br = $folder . "/" . $pkg . "-" . $branch . ".tar.gz";				
				
	# remove branch				
	$self->{ssh}->remove($br);
				
	# remove the current branch
	$self->{ssh}->put($tmp, $br, perm=>0777 );
					
	`rm $tmp`;		
	
	$self->{ssh}->disconnect();	

	# done
	return 1;

}
