#
#  Drib::Cmd::Cron
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

# package
package Drib::Cmd::Cron;

# version
our $VERSION => "1.0";

# packages we need
use File::Basename;
use File::Find;
use POSIX;
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
		'tmp' => $drib->{tmp},
		
		# db
		'db' => new Drib::Db('crons',$drib->{var}),
		
		# commands
		'commands' => [
			{ 
				'name' => 'cron',
				'help' => '', 
				'alias' => [],
				'options' => [
					Switch('edit|e'),
					Switch('list|l'),
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
	
	# figure out if they have one arg
	if ( scalar @args > 0 )	 {
	
		# need edit or list
		if ( $opts->{edit} == 0 && $opts->{list} == 0 ) {
			return {
				'code' => 400,
				'message' => "usage: drib cron <package> -list -edit"
			};
		}
		
		# parse the package name
		my $pkg = $self->{drib}->parsePackageName( $args[0] );
		
			# bad package
			unless ( $self->{drib}->{packages}->get($pkg->{pid}) ) {
				return {
					'code' => 400,
					'message' => "Package $args[0] is not installed."
				}
			}
	
		# what to do 
		if ( $opts->{edit} ) {
			return $self->edit($pkg->{pid});
		}
		else {
			$self->list($pkg->{pid});
		}
	
	}
	
	# bad
	return {
		'code' => 401,
		'message' => "You must supply a package"
	};
	
}	
	
##
## @brief add crons to execute
##
## @param $pid package id
## @param $crons array of crons to add
##
sub add {
	
	# stuff
	my ($self, $pid, $cron) = @_;

	# crons 
	my @crons = ();

	# loop me
	foreach my $c ( @{$cron} ) {
		push(@crons, $c->{cmd});
	}	

	# add to package list
	$self->{db}->set($pid,\@crons);	

	# rebuild
	$self->_rebuild();

	# do it
	return {
		'code' => 200,
		'message' => "Crons Updated"
	}

}


##
## @brief remove crons for a package
##
## @param $pid package id
##
sub remove {

	# stuff
	my ($self, $pid) = @_;

	# unset
	$self->{db}->unset($pid);

	# rebuild
	$self->_rebuild();	

}

##
## @brief edit the crons for a pacakge
## 
## @param $pid package id
##
sub edit {

	# stuff
	my ($self, $pid) = @_;
	
	# get their current crons
	my $crons = $self->{db}->get($pid);

	# save as tmp
	my $tmp = $self->{tmp} . "/" . rand_str(10);

	# loop through current and write to the file
	open(f,'>'.$tmp);
		
		# loop and write to file
		foreach my $c ( @$crons ) {
			print f $c."\n";
		}

	# close the file
	close(f);

	# now open in vi for them
	system("vi $tmp");
	
	# n 
	my @new_crons = ();
	
	# crons
	foreach $line ( split(/\n/,ws_trim(file_get($tmp))) ) {
		push(@new_crons,{'cmd'=>$line});
	}

	# remve the tmp
	`rm $tmp`;
	
	# add
	return $self->add($pid, \@new_crons);
	
}

##
## @brief list crons for a package
##
## @param $pid package id
##
sub list {

	# stuff
	my ($self, $pid) = @_;
	
	# get their current crons
	my $crons = $self->{db}->get($pid);
	
	# loop and show
	foreach my $cron ( @$crons ) {
		msg($cron);
	}
	
	exit;

}


##
## @brief rebuild the crontab
##
sub _rebuild {

	# self
	my ($self) = @_;
	
	# get a crons
	my $crons = $self->{db}->all();    	

	# file
	my $file = "";

	# get each package and 
	foreach my $pkg ( keys %{$crons} ) {
		foreach $cron ( @{$crons->{$pkg}} ) {
			$file .= $cron."\n";
		}
	}

	# save as tmp
	my $tmp = $self->{tmp} . "/" . rand_str(10);

	# put into tmp
	file_put($tmp,$file);

	# blast away the cron file
	`crontab -u root -r`;

	# set our new one
	`crontab -u root $tmp`;

	# no more temo
	`rm $tmp`;

}