#
#  drib::external
# =================================
#  (c) Copyright Travis Kuhl 2009-10
#  
#
# This is free software. You may redistribute copies of it under the terms of
# the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
# There is NO WARRANTY, to the extent permitted by law.
#

package Drib::External;

use Data::Dumper;

# what we can export
our @EXPORT = qw(
    @Repos
);

# function map
my %mapper = (
    'yum' => \&yum,
    'pear' => \&pear,
    'pecl' => \&pecl,
  #  'cpan' => \&cpan
);

# named preos
our @Repos = keys %mapper;

# go 
sub _map {

    # pkg
    my $project = shift;
    my $pkg = shift;
    my $ver = shift;
    my $branch = shift;

    # execute
    $mapper{$project}($pkg,$ver,$branch);

}

sub pear {
    
    # my
    my $name = shift;
    my $ver = shift;
    my $branch = shift;

    # see if this version exist
    print `sudo pear install $name-$ver`;
    
}

sub yum {
    # my
    my $name = shift;
    my $ver = shift;
    my $branch = shift;

    print `sudo yum install $name -y -q --skip-broke --nogpgcheck`;

}

sub pecl {

    # my
    my $name = shift;
    my $ver = shift;
    my $branch = shift;
    
    	if ($ver) {$name .= "$ver";}

    print `sudo pecl install $name`;

}

# todo
sub cpan {

}