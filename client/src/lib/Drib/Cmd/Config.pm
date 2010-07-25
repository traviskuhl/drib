#
#  Drib::Cmd::Config
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package our config
package Drib::Cmd::Config;

# version
our $VERSION => "1.0";

# packages we need
use Digest::MD5 qw(md5_hex);
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
		'tmp' => $drib->{tmp},							# tmp folder name
		
		# db
		'db' => new Drib::Db('config',$drib->{var}),	# load the db
		
		# commands
		'commands' => [
			{ 
				'name' => 'config',
				'help' => '', 
				'alias' => [],
				'options' => [
					Switch('unset|u')
				]
			}
		]
		
	};

	# bless and return me
	bless($self); return $self;

}


##
## @brief parse the command line and execute proper sub
##
## @param $cmd the cammand given
## @param $opts command line opts
## @param @args list of arguments
##
sub run {

	# get some stuff
	my ($self, $cmd, $opts, @args) = @_;
	
	# if there are more than 1 arg we show a list
	if ( scalar @args >= 1 ) {
	
		# msg
		my @msg = ();
				
		# set 
		foreach my $arg (@args) {
			
			# split out key and val
			my ($key,$val) = split(/\=/,$arg,2);

			# push it
			push(@msg, $self->set($key,$val)->{message});			
			
		}
	
		# return to the parent with a general message
		return {
			'message' => join("\n",@msg),
			'code' => 0
		};	
	
	}
	else {
		$self->list();
	}
	
}

##
## @brief show a list of config vars
##
##
sub list {

	# self
	my ($self) = @_;

    # all
    my $config = $self->{db}->all();

    # loop through and print them
    foreach my $c ( keys %{$config} ) {
        msg(" $c: $config->{$c} ");
    }
	
	# done
	exit;

}

##
## @brief get a config var. pass through to db
##
## @param $key config var key name
##
sub get {

	# what
	my ($self, $key) = @_;

	# return
	return $self->{db}->get($key);

}

##
## @brief set a config var, pass through to db
##
## @param $key var key name
## @param $val var value
##
sub set {

	# what
	my ($self, $key, $value) = @_;

	# return
	$self->{db}->set($key, $value);

	return {
		'code' => 200,
		'message' => "Set $key=$value"
	}

}
