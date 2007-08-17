#!perl -w
# $Id: 01-dependencies.t,v 1.4 2007/08/17 21:26:08 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 3;

use CPAN::FindDependencies 'finddeps';

my $devnull; my $oldfh;
open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
my $dist = CPAN::Shell->expand("Module", "CPAN")->distribution()->id();
select($oldfh) if($oldfh);

is_deeply([finddeps('CPAN')], [finddeps($dist)],
    "A module and its distribution have the same dependencies");

ok((finddeps('CPAN'))[0]->name() eq 'CPAN',
    "First entry in lists is the module itself");

is_deeply([sort { $a cmp $b } qw(CPAN Test::More Test::Harness File::Spec Scalar::Util File::Temp)],[sort { $a cmp $b } map { $_->name() } finddeps('CPAN')],
    "Dependencies are correct (horribly fragile test!)");
