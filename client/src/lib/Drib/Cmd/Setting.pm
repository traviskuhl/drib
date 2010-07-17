#
#  Drib::Cmd::Setting
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package
package Drib::Cmd::Setting;

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

# new 
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
				'name' => 'set',
				'help' => '', 
				'alias' => [],
				'options' => [

				]
			},
			{ 
				'name' => 'unset',
				'help' => '', 
				'alias' => [],
				'options' => [

				]
			}			
		]
		
	};

	# bless and return me
	bless($self); return $self;

}

##
## @brief set a package setting
##
## @param $pid package id
## @param $settings hashref of settings to set
##
sub set {


}

##
## @brief unset a package sett
##
## @param $pid package id
## @param $settings hashref of setting to unset
##
sub unset {


}

##
## @brief get all settings for a package
##
## @param $pid package id
##
sub get {


}

##
## @brief add a list of settings files
##
## @param $pid package id
## @param $files settings files
##
sub file {


}