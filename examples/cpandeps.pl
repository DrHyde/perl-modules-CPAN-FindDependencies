use strict;
use warnings;

use CPAN::FindDependencies;

my @dependencies = CPAN::FindDependencies::finddeps(shift);
foreach my $dep (@dependencies) {
    print '  ' x $dep->depth();
    print $dep->name().' ('.$dep->distribution().")\n";
}
           
