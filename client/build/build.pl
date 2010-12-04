#!/usr/bin/perl
#
#

use lib "../src/lib";

use POSIX;
use Drib::Utils;

# files 
my $base = "/tmp/".time();
my $tmp = $base."/drib"; `mkdir -p $tmp`;

# get the build version from the changelog
my $version = `egrep -m 1 "Version [0-9\.]+" ../pkg/changelog | sed 's/Version //'`; chomp($version);

# name of build
my $name = "drib-".$version.".tar";

# check it 
if ( -e "./archive/$name" ) {
	die("Build $version already exists.");
}

# now start copying some things over
`cp -r ../src/bin $tmp`;

# open drib and give it the right version number
my $file = file_get("$tmp/bin/drib");

# replace it 
$file =~ s/VERSION \= "([0-9.]+)"/VERSION \= "$version"/gi;

# put it back
file_put("$tmp/bin/drib",$file);

# move others
`cp -r ../src/lib $tmp`;
`mkdir $tmp/var`;
`cp ../src/configure $tmp`;
`cp ../src/README $tmp`;
`cp ../src/LICENSE $tmp`;

# where 
my $pwd = getcwd();

# move
chdir($tmp."/..");

# tar it
`tar -cf $name ./drib`;

# copy to pub
`cp $name /home/bolt/share/htdocs/drib/it/pub`;

# now move it to builds
`mv $name $pwd/archive`;

# remove it
`rm -r $base`;

# all done
print "Done!\n";
