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

package Drib::Dist::Remote;

use Drib::Utils;
use Data::Dumper;
use POSIX;

# version
my $VERSION = "0.0.1";

sub new {

	# get some
	my ($ref, $drib) = @_;

	# get myself
	my $self = {
		
		# drib
		'drib' 		=> $drib,
		
		# folder
		'folder' 	=> "",
		
		# some params we need
		'ssh'		=> 0,
					
	};

		
	# bless and return me
	bless($self); return $self;

}

sub connect {

	my ($self) = @_;
	
	# have ssh
	if ( $self->{ssh} != 0 ) {
		return;
	}
	
	# get info we need
	my $host = $self->{drib}->{modules}->{Config}->get("dist-remote-host");
	my $port = $self->{drib}->{modules}->{Config}->get("dist-remote-port") || 22;
	my $folder = trim($self->{drib}->{modules}->{Config}->get("dist-remote-folder"))."/";
	
	# if no
	unless ( $host && $folder ) {
		fail("You need to define server & folder (port optional, defaults to 22):\n drib config dist-remote-host=<hostname>\n drib config dist-remote-port=<port>\n drib config dist-remote-folder=<folder>");
	}

	# set folder
	$self->{folder} = $folder;
	$self->{host} = $host;

	# ssh
	$self->{ssh} = $self->{drib}->{remote}->new($self->{drib}, $host, $port);

}


sub check {

	# check
	my ($self, $project, $pkg, $ver) = @_;
	
	# connect
	$self->connect();
	
	# try to stat the file
	my $file = $self->{folder} . $project."/".$pkg."/".$pkg."-".$ver.".tar.gz";

	# lets try status
	my $resp = $self->{ssh}->exec("stat $file");
	
	# what up
	if ( $resp =~ 'No such file or directory' ) {
		return 0;
	}
	else {
		return 1;
	}

}

sub get {

	my ($self, $project, $pkg, $ver) = @_;
	
	# connect    
    $self->connect();	
	
	# try to stat the file
	my $file = $self->{folder} . $project."/".$pkg."/".$pkg."-".$ver.".tar.gz";

	# tmp file
	my $tmp = $self->{drib}->{tmp} ."/" . rand_str(5);
	
	# try to get it 
	$resp = $self->{ssh}->scp($self->{host}.":".$file,$tmp);
	
	# bad reso
	if ( $resp == 0 ) {
		return 0;
	}
	
	# get tar
	$tar = file_get($tmp);
		
	# rm tmp
	`rm $tmp`;	
		
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
	
		# make the folder
		$self->{ssh}->exec("mkdir -p $folder");		
			
	# tmp
	my $tmp = $self->{drib}->{tmp} . "/" . rand_str(10);			
	
	# save it 
	file_put($tmp,$tar);	
	
	# chmod to the proper perm
	`chmod 0664 $tmp`;
	
	# file
	my $file = $folder . "/" . $pkg . "-" . $version . ".tar.gz";
	
		# try to get it 
		$resp = $self->{ssh}->scp($tmp, $self->{host}.":".$file);
							
	# bracnh fiuel
	$br = $folder . "/" . $pkg . "-" . $branch . ".tar.gz";				
								
		# set in branch
		$resp = $self->{ssh}->scp($tmp, $self->{host}.":".$br);
					
	`rm $tmp`;		

	# done
	return 1;

}
