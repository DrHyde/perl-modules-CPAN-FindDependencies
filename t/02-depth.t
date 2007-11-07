#!perl -w
# $Id: 02-depth.t,v 1.4 2007/11/07 23:32:36 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 1;

use CPAN::FindDependencies 'finddeps';

my %deps = map { $_->name(), $_->depth() } finddeps('CPAN', nowarnings => 1);

ok($deps{CPAN} == 0, "The 'root' module has zero depth");

# # fragile tests
# ok($deps{'Test::More'} == 1 &&
#    $deps{'Scalar::Util'} == 1 &&
#    $deps{'File::Temp'} == 1,
#     "Its immediate dependencies have depth 1");
# ok($deps{'Test::Harness'} == 2, "A dependency's dependency has depth 2");
# ok($deps{'File::Spec'} == 3, "A dependency's dependency's dependency has depth 3");
