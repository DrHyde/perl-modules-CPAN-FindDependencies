#!perl -w
# $Id: 02-withdepth.t,v 1.3 2007/08/16 22:27:17 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 5;

use CPAN::FindDependencies 'finddeps';

# $SIG{__WARN__} = sub { }; # silently eat warnings

ok(!exists((finddeps('CPAN'))[0]->{_depth}),
    "No _depth field if we don't ask for it");

my %deps = map { $_->{ID}, $_->{_depth} } finddeps('CPAN', withdepth => 1);

ok($deps{CPAN} == 0, "The 'root' module has zero depth");
ok($deps{'Test::More'} == 1 &&
   $deps{'Scalar::Util'} == 1 &&
   $deps{'File::Temp'} == 1,
    "Its immediate dependencies have depth 1");
ok($deps{'Test::Harness'} == 2, "A dependency's dependency has depth 2");
ok($deps{'File::Spec'} == 3, "A dependency's dependency's dependency has depth 3");
