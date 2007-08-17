#!perl -w
# $Id: 01-dependencies.t,v 1.5 2007/08/17 22:14:11 drhyde Exp $
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
    [map { [$_->depth(), $_->name(), $_->distribution() ] } finddeps('CPAN')],
    [map { [$_->depth(), $_->name(), $_->distribution() ] } finddeps($dist)],
    "A module and its distribution have the same dependencies");

ok((finddeps('CPAN'))[0]->name() eq 'CPAN',
    "First entry in lists is the module itself");
