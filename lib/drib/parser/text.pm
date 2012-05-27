# drib::parser::text

package drib::parser::text;

# what we can export
our @EXPORT = qw(
    &ext
);

# ext
sub ext {
	return "dpf";
}

sub parse {

	# file to parse
	my ($drib, $tmp, $replace) = @_;
	
	# open the tfile
	my $file = $drib->file_get($tmp);
	
	# no more than 2 space
	$file =~ s/\t/ /g;	
	$file =~ s/( )+/ /g;
	$file =~ s/\n\n/\n/g;	
	
	# and our replacement vars
	foreach my $key ( keys %{$replace}  ) {
		
		# get the value
		my $val = $replace->{$key};
		
		# repalce
		$file =~ s/\$\($key\)/$val/g;
		
	}	
	
	# first pass at parsing
	my $o = _parse($file);
	
		# include
		my @inc = ();
	
		# if we have more stuff
		# we should add it 
		if (scalar(@{$o->{include}}) > 0) {
			
			# open the file and parse it 
			foreach my $f (@{$o->{include}}) {
				if (-e $f) {
				
					# get the file 
					my $_o = _parse(file_get($f));
					
					# append anything 
					foreach my $key (%{$_o->{vars}}) {
						$o->{vars}{$key} = $_o->{vars}{$key};
					}
	
					# for after second parse
					push(@inc, $_o);
					
				}
			}
		
		}

	# replace vars
	foreach my $key ( keys %{$o->{vars}}  ) {
		
		my $val = $o->{vars}{$key};
		
		# repalce
		$file =~ s/\$\($key\)/$val/g;
		
	}

	# replace defaults
	$file = _replaceDefaults($file, $replace);
	$file = _replaceDefaults($file, $o->{vars});

	# fo
	my $fo = _parse($file);
	
		# append anything 
		if (scalar(@inc)) {
			foreach my $_o (@inc) {
			
			
				# set
				foreach my $key (keys %{$_o->{set}}) {					
					$fo->{set}->{$key} = $_o->{set}->{$key};					
				}
				
			}
		}

	# reparse and return
	return $fo;

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
	my $Exec = 0;
	my @include = ();
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

		# exec
		elsif ( $act =~ /exec/i ) {
			
			# zero
			$Exec = [] if $Exec == 0;
		
			# add it 
			push(@$Exec, $mline);
		
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
		
		# include
		elsif ( $act =~ /\@include/i ) {
			
			# add it to the include vars
			push(@include, $mline);  
		
		
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
		'exec'		=> $Exec,
		'vars'		=> \%vars,
		'include'	=> \@include
	};

}

sub _replaceDefaults {

	my ($file, $replace) = @_;

	# find some matches
	my @matches = ( $file =~ /\$\(([a-z\.]+)\|([^\)]+)\)/ig );
	
	# loop and replace
	for (my $i = 0; $i < $#matches; $i++ ) {	
		my $key = $matches[$i];
		my $val = $matches[++$i];
		if ( exists $replace->{$key} ) {
			$file =~ s/\$\($key\|$val\)/$replace->{$key}/i;		
		}
		else {
			$file =~ s/\$\($key\|$val\)/$val/i;
		}
	}
	
	return $file;

}

sub ws_trim {
	my $string = shift;
	$string =~ s/^\s+//;
    $string =~ s/\s$//;
	return $string;	
}

return 1;