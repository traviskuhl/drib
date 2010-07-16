#
#  drib::parser::text
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package Drib::Parsers::Text;

# what to use
use Drib::Utils;
use Switch;
use Data::Dumper;

# what we can export
our @EXPORT = qw(
    $EXENSION
);

# this is the exension
our $EXENSION = "dpf";


sub parse {

	# file to parse
	my ($self,$tmp) = @_;
	
	# open the tfile
	my $file = file_get($tmp);
	
	# no more than 2 space
	$file =~ s/\t/ /g;	
	$file =~ s/( )+/ /g;
	$file =~ s/\n\n/\n/g;	
	
	# first pass at parsing
	my $o = _parse($file,1);

	# replace vars
	foreach my $key ( keys %{$o->{vars}}  ) {
		
		my $val = $o->{vars}{$key};
		
		# repalce
		$file =~ s/\$\($key\)/$val/g;
	
	}

	# reparse and return
	return _parse($file);

}

sub _parse {

	# file
	my ($file) = @_;

	# what we need 
	my $Meta = 0;
	my $Set = 0;
	my $Dirs = 0;
	my $Files = 0;
	my $Commands = 0;
	my $Depend = 0;
	my $Cron = 0;
	my %vars = ();

	# split on new lines
	my @lines = split(/\n/,$file);
	
	# loop through each line
	foreach my $line ( @lines ) {
		
		# split on words
		my @words = split(/ /, ws_trim($line));		
	
		# no words we skipout
		if ( $#words == -1 ) { next; }
	
		# is it a comment
		if ( $words[0] eq '#' || $words[0] eq '//' ) { next; }
	
		# lw
		my @lw = @words;
	
		# action word
		my $act = $words[0];
		
		# mline
		my $mline = join(' ', splice(@words,1) );
		
		# meta
		if ( $act =~ /meta$/i ) {
			
			# zero
			$Meta = {} if $Meta == 0;
			
			# split on =
			my($key,$val) = split(/=/,$mline);
			
			# trim
			$key = lc(ws_trim($key));
			$val = ws_trim($val);
			
			# now push to meta
			$Meta->{$key} = $val;
					
		}
		
		# set
		elsif ( $act =~ /set$/i ) {
		
			# zero
			$Set = {} if $Set == 0;
		
			# key 
			$key = $lw[1];
			
			# the rest is the value
			$val = join(' ', splice(@lw,2));
			
			# set it 
			$Set->{$key} = $val;
			
		}
		
		# dir 
		elsif ( $act =~ /dir$/i ) {
		
			# dirs
			$Dirs = [] if $Dirs == 0;
			
			# d
			my $d = {};
			
			# parts
			$d->{'user'} = $lw[1] if ( $lw[1] ne '-' ); 
			$d->{'group'} = $lw[2] if ( $lw[2] ne '-' ); 
			$d->{'mode'} = $lw[3] if ( $lw[3] ne '-' ); 			
		
			# dir
			$d->{'dir'} = $lw[4];
			
			# push
			push(@{$Dirs},$d);
			
		}
		
		# file
		elsif ( $act =~ /file$/i || $act =~ /find$/i ) {
				
			# dirs
			$Files = [] if $Files == 0;
			
			# d
			my $f = {};
			
			# parts
			$f->{'user'} = $lw[1] if ( $lw[1] ne '-' ); 
			$f->{'group'} = $lw[2] if ( $lw[2] ne '-' ); 
			$f->{'mode'} = $lw[3] if ( $lw[3] ne '-' ); 			
		
			# what to add as 
			if ( $act eq 'find' ) {
			
				# root
				$f->{'root'} = $lw[5];			
			
				# find 
				$f->{'find'} = join(' ',splice(@lw,5));				

				
			}
			else {
				$f->{'src'} = $lw[5];
			}
		
			# add 
			push(@$Files,[$lw[4],$f]);
		
		}
		
		# settings file
		elsif ( $act =~ /settings$/i ) {
			
			# dirs
			$Files = [] if $Files == 0;			
			
			# simple, just add it 
			push(@$Files,[$lw[1],{'src'=>$lw[2],'settings'=>'true'}]);
		
		}
		
		# commands
		elsif ( $act =~ /command/i ) {
		
			# zero
			$Commands = {} if $Commands == 0;
		
			# lets add it 
			my $g = $lw[1];
			
			# a
			my $a = $Commands->{$g};
			
			# push it
			push(@$a, join(' ',splice(@lw,2)) );
					
			# reset
			$Commands->{$g} = $a;		
		
		}
		
		# depend
		elsif ( $act =~ /depends?/i ) {
			
			# depend
			$Depend = [] if $Depend == 0;
		
			# pakage
			my $pkg = $lw[1];
			my $min = $lw[2] || '0';
			my $max = $lw[3] || '999999999';
		
			# add 
			push(@$Depend,{'pkg'=>$pkg,'min'=>$min,'max'=>$max});
		
		}
		
		# cron
		elsif ( $act =~ /cron/i ) {
			
			# zero
			$Cron = [] if $Cron == 0;
		
			# add it 
			push(@$Cron,{'cmd'=>$mline});
		
		}
		
		# var
		elsif ( index($mline,'=') != -1 ) {
			
			# split on =
			my($key,$val) = split(/=/,join(' ',@lw));			
			
			# trim
			$key = ws_trim($key);
			$val = ws_trim($val);
			
			# send to vars
			$vars{$key} = $val;
		
		}
		
	}

	return {
 		'meta'		=> $Meta,
 		'set'		=> $Set,
 		'dirs'		=> $Dirs,
 		'files' 	=> $Files,
 		'cmd' 		=> $Commands,
		'depend'	=> $Depend,
		'cron'		=> $Cron,
		'vars'		=> \%vars
	};

}

return 1;
