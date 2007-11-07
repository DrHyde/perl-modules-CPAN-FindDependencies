#!perl -w
# $Id: 04-build_requires.t,v 1.1 2007/11/07 23:32:36 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 1;

use CPAN::FindDependencies 'finddeps';

ok((grep { $_->name() eq 'Module::Build' } finddeps('File::Spec', nowarnings => 1)),
    'build_requires works');
