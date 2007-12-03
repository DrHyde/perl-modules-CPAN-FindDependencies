#!perl -w
# $Id: chkenv.pm,v 1.3 2007/12/03 17:46:48 drhyde Exp $
use strict;

use Test::More;
use LWP::Simple;

unless(
    get("http://search.cpan.org/~dcantrell/") &&
    get("http://www.cpan.org/modules/02packages.details.txt.gz")
) {
    plan skip_all => "Need web access to the CPAN";
    exit;
}

1;
