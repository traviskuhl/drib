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
		
		# dbs
		'db' => new Drib::Db('config',$drib->{var}),		# load the db
		'mdb' => new Drib::Db('manifests',$drib->{var}),	# load the manifest db
		
		# commands
		'commands' => [
			{ 
				'name' => 'config',
				'help' => '', 
				'alias' => [],
				'options' => [
					Switch('unset|u')
				]
			},
			{
				'name' => 'manifest',
				'help' => '',
				'alias' => ['ls-manifest', 'ls-manifests', 'list-manifest', 'add-manifest', 'rm-manifest', 'up-manifest'],
				'options' => []
			
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
	my ($self, $cmd, $opts) = @_;
	
	# args
	my @args = @{$self->{drib}->{args}};
	
	# manifest commands
	if ( $cmd eq 'manifest' ) {
	
		# things to watch for arg1
		my @a1 = ('add', 'ls', 'rm', 'up', 'list');
		
		# the orignal command without aliased
		my $oc = $self->{drib}->{cmd};	
	
			# check me out
			if ( scalar @args > 0 && in_array(\@a1, $args[0]) ) {
				$oc = (shift @args)."-manifest"; 
			}
		
		# add a manifest
		if ( $oc eq "add-manifest" || $oc eq 'update-manifest' ) {
			return $self->addManifest( shift(@{$self->{drib}->{args}}) );
		}
		
		# list all manifests
		elsif ( $oc eq 'ls-manifest' || $oc eq 'ls-manifests' || $oc eq 'list-manifest' ) {
			
			# all
			my %all = %{$self->{mdb}->all()};
			
			# add a manifest
			foreach my $item ( keys %all ) {
				if ( $all{$item} ) {
					msg(" $item");			
				}
			}
		
			exit();
		
		}	

		# remove a manifest			
		elsif ( $oc eq 'rm-manifest' ) {
		
			# remove it 
			$self->{mdb}->unset( shift @{$self->{drib}->{args}} );
		
			return {
				"message" => "Manifest removed",
				"code" => 200
			}
		
		}			
		elsif ( scalar @{$self->{drib}->{args}} == 1 ) {
		
			# get the manifest
			my $man = $self->{mdb}->get($self->{drib}->{args}[0]);
			
				# not a good manifest
				unless ($man) {
					return {
						"message" => "Unknown manifest",
						"code" => 404
					};
				}
			
			# show it 
			my $j = new JSON;
			
			# print print and indent
			$j->pretty(1)->indent;
			$j->space_after(1);
			$j->space_before(0);
		
			# encode and print
			print $j->encode($man);
			
			# exit out
			exit();
		
		}
		else {
			return {
				"message" => "Unknown manifest command",
				"code" => 400
			};
		}
	
	}

	# normal config
	elsif ( scalar @{$self->{drib}->{args}} >= 1 ) {
	
		# msg
		my @msg = ();
				
		# set 
		foreach my $arg (@{$self->{drib}->{args}}) {

			# unset
			if ( $opts->{unset} ) {
			
				# just unset
				push(@msg, $self->unset($arg)->{message});			
				
			}
			else {
			
				# split out key and val
				my ($key,$val) = split(/\=/,$arg,2);			
			
					# no key we should skup
					if ( $key eq "" ) { next; }
			
				# push onto our array
				push(@msg, $self->set($key,$val)->{message});			
				
			}
			
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
    	if ( $c ne "repos" ) {
	        msg(" $c: $config->{$c} ");
		}
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

##
## @brief get all config vars, pass through to db
##
## @param $key var key name
## @param $val var value
##
sub all {

	# what
	my ($self) = @_;

	# return
	return $self->{db}->all();

}

##
## @brief unset a config var, pass through to db
##
## @param $key var key name
## @param $val var value
##
sub unset {

	# what
	my ($self, $key) = @_;

	# return
	$self->{db}->unset($key);

	return {
		'code' => 200,
		'message' => "Unset $key"
	}

}

##
## @brief add a manifest to the build and depoy list
##
## @param $manifest manifest file
##
sub addManifest {

	# get stuff
	my ($self, $manifest, $force) = @_;
	
	# lets make sure it exists
	unless ( -e $manifest ) {
		return {
			"code" => 404,
			"message" => "manifest does not exist"
		};
	}

	# open and parse it 
	my $m = from_json( file_get($manifest) );

	# make sure a manifest by this name doesn't 
	# already exist
	if ( $self->{mdb}->get($m->{name}) && $force != 1 ) {
		return {
			"message" => "Manifest $m->{name} already exists",
			"code" => 400
		};
	}
	
	# add it 
	$self->{mdb}->set($m->{name}, $m);

	# done
	return {
		"message" => "Manifest Added",
		"code" => 200
	}

}
