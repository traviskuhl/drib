#
#  Drib::Manifest
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package up
package Drib::Manifest;

# version number is good
my $VERSION = "1.0";

# external
use JSON;
use POSIX;

# drib
use Drib::Utils;

sub new {

	# get some
	my ($ref, $file) = @_;

	# get myself
	my $self = {
		
		# drib
		'_drib' => $drib,
		
		# holders
		'_raw' => "",
		'_obj' => {},
		'_version' => 0,
		
		# these are part of the each manifest
		'project' => "",
		'name' => "",
		'meta' => {},
		'secure' => 0,
		'set' => {
			'vars' => {},
			'files' => ()
		},
		'crons' => {},
		'commands' => {},
		'changelog' => "",
		'depend' => {},
		'files' => ()
			
	};	
	
	# bless and return me
	bless($self); 	
	
	# connect
	$self->connect();	
	
	# done
	return $self;

}

sub set {

}

sub get {

}

sub parse {

}

sub generate {

}

sub _convert {


}