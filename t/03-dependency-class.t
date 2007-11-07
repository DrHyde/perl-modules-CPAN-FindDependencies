#!perl -w
# $Id: 03-dependency-class.t,v 1.2 2007/11/07 23:32:36 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 2;

use CPAN::FindDependencies 'finddeps';

my $dep = (finddeps('CPAN', nowarnings => 1))[0];

ok($dep->name() eq 'CPAN', 'Dependency object gives the right name for modules');
ok($dep->distribution() =~ m!^A/AN/ANDK/CPAN-!, 'Dependency object gives the right distribution for modules');
