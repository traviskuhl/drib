#
#  drib::parser::perl
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package me
package drib::parser::perl;

# what to use
use drib::utils;
use Data::Dumper;

# what we can export
our @EXPORT = qw(
    $EXENSION
);

# this is the exension
our $EXENSION = "pkg";

sub parse {

	# file to parse
	my ($self,$tmp) = @_;
	
	# what we need 
	our $Meta = 0;
	our $Set = 0;
	our $Dirs = 0;
	our $Files = 0;
	our $Commands = 0;
	our $Depend = 0;
	our $Cron = 0;
	
	# try to include the file
	eval {
		do "$tmp";
	};
	
	# don't need the file anymore
	unlink $tmp;
	
	# if we couldn't we need to fail
	if ($@) {
		fail("Could not parse the Build Manifest");
	}	
		
	# make sure we have what we need
 	if ( $Meta == 0) {
 		fail("Meta variable not defined in Build Manifest");
 	}
 	
 	# object ot return
 	my $o = {
 		'meta'		=> $Meta,
 		'set'		=> $Set,
 		'dirs'		=> $Dirs,
 		'files' 	=> $Files,
 		'cmd' 		=> $Commands,
		'depend'	=> $Depend,
		'cron'		=> $Cron
 	};

	# give back
	return $o;

}