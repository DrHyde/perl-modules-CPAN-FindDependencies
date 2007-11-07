#!perl -w
# $Id: 01-dependencies.t,v 1.6 2007/11/07 23:32:36 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 2;

use CPAN::FindDependencies 'finddeps';

my $devnull; my $oldfh;
open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
my $dist = CPAN::Shell->expand("Module", "CPAN")->distribution()->id();
select($oldfh) if($oldfh);

is_deeply(
    [map { [$_->depth(), $_->name(), $_->distribution() ] } finddeps('CPAN', nowarnings => 1)],
    [map { [$_->depth(), $_->name(), $_->distribution() ] } finddeps($dist, nowarnings => 1)],
    "A module and its distribution have the same dependencies");

ok((finddeps('CPAN', nowarnings => 1))[0]->name() eq 'CPAN',
    "First entry in lists is the module itself");
