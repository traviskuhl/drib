#
#  drib::dist::public
# =================================
#  (c) Copyright Travis Kuhl 2009-11
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package Drib::Dist::Public;

use Drib::Utils;
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;

# version
my $VERSION = "1.0";

sub new {

	# get 
	my($this, $drib, $config) = @_;

	# class
	my $class = ref($this) || $this;

	# get myself
	my $self = {
		
		# drib
		'drib' => $drib,
		
		# folder
		'base' => $config->{base},
		'path' => $config->{path}
	
	};	
	
	# bless and return me
	bless($self, $class); return $self;

}

sub _buildUrl {

	# get some stuff
	my ($self, $project, $pkg, $ver) = @_;

	# localize our path
	my $path = $self->{path};
	
		# replace some vars
		$path =~ s/\%project/$project/ig;
		$path =~ s/\%name/$pkg/ig;
		$path =~ s/\%version/$ver/ig;

	# make our url
	return $self->{base} . $path;

}

sub _req {
	
	# self
	my ($self, $type, $url) = @_;
	
	$req = HTTP::Request->new($type => $url);	
	
	# user agent
	$ua = LWP::UserAgent->new;
	
	# return
	return $ua->request($req);

}

sub check {
	
	my ($self, $project, $pkg, $ver) = @_;
	
	# figure it 
	return $self->_req(HEAD, $self->_buildUrl($project, $pkg, $ver))->is_success;
	
}

sub get {

	my ($self, $project, $pkg, $ver) = @_;
	
	# req
	my $r = $self->_req("GET", $self->_buildUrl($project, $pkg, $ver));

	if ( $r->is_success ) {
		return $r->content;
	}
	else {
		return 0;
	}

}

sub upload {

	my ($self,$info) = @_;
	
	# done
	return 0;

}