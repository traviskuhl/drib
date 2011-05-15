#
#  Drib::Cmd::Deploy
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# build
package Drib::Cmd::Deploy;

# version
our $VERSION => "1.0";

# drib
use Drib::Utils;

# packages we need
use File::Basename;
use File::Find;
use POSIX;
use Digest::MD5 qw(md5_hex);
use JSON;
use Getopt::Lucid qw( :all );
use Data::Dumper;

# new 
sub new {

	# get 
	my($ref, $drib) = @_;
	
	# self
	my $self = {
		
		# drib 
		'drib' => $drib,
		
		# shortcuts
		'tmp' => $drib->{tmp},
		
		# commands
		'commands' => [
			{ 
				'name' => 'deploy',
				'help' => '', 
				'alias' => ['de'],
				'options' => [
					
				]
			}
		]
		
	};

	# bless and return me
	bless($self); return $self;

}

##
## @brief run the create 
##
sub run {
	
	# get some stuff
	my ($self, $cmd, $opts) = @_;
	
	# args
	my @args = @{$self->{drib}->{args}};
		
	if ( $args[0] eq "execute" ) {
		
		# execute
		return $self->execute( from_json($args[1]) );
			
	}
	else {
		
		# file
		$file = shift @args;
		
			# make sure it's a file
			unless ( -e $file ) {
				return {
					"message" => "Build file not valid",
					"code" => 400
				};
			}
		
		# run each build
		return $self->deploy($file, \@args, $opts)->{message};
		
	}

	
}


##
## @brief deploy a given build
##
## @param $file build file
## @param $targets named targets to execute
## @param $opts builds options
##
sub deploy {

	# get manifest
	my ($self, $file, $targets, $opts) = @_;
		
	# open the build manifest and parse
	my $m = from_json( file_get($file) );
		
	# check for a build cmd
	unless ( $m->{deploy} ) {
		return {
			"message" => "No deploy instructions in $man",
			"code" => 404
		};
	}
	
	# build
	my %deploy = %{$m->{deploy}};
	
	# loop through each target and run our reploy
	foreach my $target ( keys %deploy ) {
		
		# get the manifest
		my $man = $deploy{$target};		
		
		# password
		my $pass = 0;		
		
		# ask for a password
		if ( $man->{useMasterPassword} ) {
			$pass = ask("Master Password:", 1);
		}				
		
		# tmp
		my $tmp = $self->{tmp} . "/" . rand_str(5);
		
		# remote name
		my $rtmp = "/tmp/deploy-" . rand_str(5);
		
			# put our man
			file_put($tmp, to_json($man));
		
		# now loop through each host
		# and scp our manifest
		foreach my $host ( @{$man->{hosts}} ) {			
			
			msg("staritng $host->{host}");
			msg(("="x50));
			
			# connect to remove
			my $r = new Drib::Remote($self->{drib}, $host->{host}, ($host->{port} || 22), ($host->{pass} || $pass), $host->{user} );
			
			msg("pushing manifest ($rtmp) to remote...");
			
			# send our tmp
			$r->scp($tmp, $rtmp);
			
			msg("pushed. starting execute...");
			
			# execute our command
			print $r->exec("sudo /usr/local/bin/drib deploy execute $rtmp");
			
			# end
			msg(("="x50)."\n");
			
		}
	
	}
		
}


## execute
sub execute {

	# get manifest
	my ($self, $man) = @_;
	
	print Dumper($man);

}