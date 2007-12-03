#!perl -w
# $Id: 01-dependencies.t,v 1.7 2007/12/03 17:46:47 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 1;

use CPAN::FindDependencies 'finddeps';

ok((finddeps('CPAN', nowarnings => 1))[0]->name() eq 'CPAN',
    "First entry in lists is the module itself");
# FIXME add more here
