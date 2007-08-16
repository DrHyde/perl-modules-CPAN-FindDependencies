#!perl -w
# $Id: chkenv.pm,v 1.2 2007/08/16 22:27:17 drhyde Exp $
use strict;

use CPAN;
use Test::More;
use LWP::UserAgent;
use Sys::Hostname;

my $dist = eval {
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    my $dist = CPAN::Shell->expand("Module", "CPAN")->{RO}->{CPAN_FILE};
    select($oldfh) if($oldfh);
    $dist;
};

if($@ || !$dist) {
    plan skip_all => "Need functional CPAN.pm.  Check permissions";
    exit;
}

unless(
    LWP::UserAgent->new(
        agent => "CPAN-FindDependencies-testsuite/1",
        from => hostname()
    )->request(HTTP::Request->new(
        GET => "http://search.cpan.org/~dcantrell/"
    ))->is_success()
) {
    plan skip_all => "Need web access to http://search.cpan.org/";
    exit;
}

1;
