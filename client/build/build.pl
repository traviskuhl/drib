#!/usr/bin/perl
#
#

use lib "../src/lib";

use POSIX;
use Drib::Utils;

# where 
my $pwd = getcwd();

# build the package
`sudo /usr/local/bin/drib create ../pkg/drib.dpf`;

$tar = `find ./ -maxdepth 1 -name '*.tar.gz'`; 
$tar =~ s/\n//g;

# copy to current
`cp -f ./$tar $pwd/pkg/drib-current.tar.gz`;

# move it 
`mv $tar $pwd/pkg`;

# files 
my $base = "/tmp/".time();
my $tmp = $base."/drib"; `mkdir -p $tmp`;

# get the build version from the changelog
my $version = `egrep -m 1 "Version [0-9\.]+" ../pkg/changelog | sed 's/Version //'`; chomp($version);

# name of build
my $name = "drib-".$version.".tar";

# check it 
if ( -e "./tar/$name" ) {
	die("Build $version already exists.");
}

# now start copying some things over
`cp -r ../src/bin $tmp`;

# open drib and give it the right version number
my $file = file_get("$tmp/bin/drib");

# replace it 
$file =~ s/VERSION \= "([0-9.]+)"/VERSION \= "$version"/gi;

# put it back
file_put("$tmp/bin/drib", $file);

# move others
`cp -r ../src/lib $tmp`;
`mkdir $tmp/var`;
`cp ../configure $tmp`;
`cp ../README.md $tmp`;
`cp ../LICENSE $tmp`;
`cp -r ../pkg $tmp`;

# move
chdir($tmp."/..");

# tar it
`tar -cf $name ./drib`;

# now move it to builds
`mv $name $pwd/tar`;

# remove it
`rm -r $base`;

# all done
print "Done!\n";
