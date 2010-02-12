#
#  drib::utils
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package drib::utils;

use Data::Dumper;
use JSON;
use base qw(Exporter);


our @EXPORT = qw(
	trim
	file_get
	file_put
	fail
	msg
	verbose
	rand_str
	force_root
	in_array
	plural
	ask
	versioncmp
);

sub trim {
	my $string = shift;
	my $both = shift || 0;
	if ( $both  ) {
    	$string =~ s/^\///;
    }
    $string =~ s/\/$//;
	return $string;	
}

sub file_get {
	
	my ($file) = @_;

	open(FH,$file);
	my @f = <FH>;
	close(FH);
	
	return join("",@f);

}

sub file_put {
	
	my ($file,$content) = @_;

	open(FH,">".$file) || fail("Could not write to $file");
	print FH $content;
	close(FH);

}

sub fail {
	my $msg = shift;
	print $msg ."\n";
	exit;
}

sub msg {
	my $msg = shift;
	print $msg ."\n";
}

sub verbose {
	my $msg = shift;
	print $msg ."\n";
}

sub rand_str {
	my $length_of_randomstring=shift;# the length of 
			 # the random string to generate

	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		# rand @chars will generate a random 
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

sub force_root {
    
    if ( $> != 0 ) {
        fail("Must run install commands as 'root'.");
    }

}

sub in_array {
    my ($arr,$search_for) = @_;
    foreach my $value (@$arr) {
        return 1 if $value eq $search_for;
    }
    return 0;
}

sub plural {
    my ($str,$len) = @_;
    $len++;
    
    return $str if ($len==1);
    
    if ( substr($str,-1) eq 'y' ) {
        return substr($str,-1). 'ies';
    }
    else {
        return $str . 's';
    }
}

sub ask {

    # whas the question
    my $q = shift;
    my $p = shift;
    
    # ask it
    print $q . " ";
    
    if ( $p ) {
    	`stty -echo`;
    }
    
    # wait for an answer
    my $a = <STDIN>; chomp $a;

    if ( $p ) {
    	`stty echo`; print "\n";
    }
    
    # give it back
    return $a;
    
}


# --- copied from: Sort::Versions    ---
# --- below copyright applies to END ---
#  Copyright (c) 1996, Kenneth J. Albanowski. All rights reserved.  This
#  program is free software; you can redistribute it and/or modify it under
#  the same terms as Perl itself.
sub versioncmp {
    my @A = ($_[0] =~ /([-.]|\d+|[^-.\d]+)/g);
    my @B = ($_[1] =~ /([-.]|\d+|[^-.\d]+)/g);

    my ($A, $B);
    while (@A and @B) {
	$A = shift @A;
	$B = shift @B;
	if ($A eq '-' and $B eq '-') {
	    next;
	} elsif ( $A eq '-' ) {
	    return -1;
	} elsif ( $B eq '-') {
	    return 1;
	} elsif ($A eq '.' and $B eq '.') {
	    next;
	} elsif ( $A eq '.' ) {
	    return -1;
	} elsif ( $B eq '.' ) {
	    return 1;
	} elsif ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
	    if ($A =~ /^0/ || $B =~ /^0/) {
		return $A cmp $B if $A cmp $B;
	    } else {
		return $A <=> $B if $A <=> $B;
	    }
	} else {
	    $A = uc $A;
	    $B = uc $B;
	    return $A cmp $B if $A cmp $B;
	}	
    }
    @A <=> @B;
}
# --- END ---
