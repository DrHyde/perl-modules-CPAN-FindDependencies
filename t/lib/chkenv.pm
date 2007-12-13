#!perl -w
# $Id: chkenv.pm,v 1.4 2007/12/13 15:16:03 drhyde Exp $
use strict;

use Test::More;
use LWP::Simple;

unless(
    head("http://search.cpan.org/~dcantrell/") &&
    head("http://www.cpan.org/modules/02packages.details.txt.gz")
) {
    plan skip_all => "Need web access to the CPAN";
    exit;
}

1;
