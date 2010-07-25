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

# version
my $VERSION = "0.0.1";

sub new {

	# get some
	my ($ref, $drib) = @_;

	# get myself
	my $self = {
		
		# some params we need
		'host'		=> $drib->{modules}->{Config}->get("dist-remote-host"),
		'port'		=> $drib->{modules}->{Config}->get("dist-remote-port") || 22,
		'folder'	=> trim($drib->{modules}->{Config}->get("dist-remote-folder"))."/"
			
	};
	
	# unless we're in confif
	unless ( $drib->{cmd} == 'config' ) {
		
		# if no
		unless ( $self->{host} && $self->{folder} ) {
			fail("You need to define server & folder (port optional, defaults to 22):\n drib config dist-remote-host=<hostname>\n drib config dist-remote-port=<port>\n drib config dist-remote-folder=<folder>");
		}
	
		# ssh
		$self->{ssh} = $drib->{remote}->connect($self->{host}, $self->{port});
		
	}
		
	# bless and return me
	bless($self); return $self;

}


sub check {

	# check
	my ($self, $project, $pkg, $ver) = @_;
	
	# try to stat the file
	my $file = $self->{folder} . $project."/".$pkg."/".$pkg."-".$ver.".tar.gz";

	# lets try status
	my $resp = $self->{ssh}->exec("stat $file");
	
	print Dumper($resp);

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
