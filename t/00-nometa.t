#!perl -w
# $Id: 00-nometa.t,v 1.7 2007/08/19 11:57:11 drhyde Exp $
use strict;

use Test::More;
require 't/lib/chkenv.pm';
plan tests => 7;

use_ok('CPAN::FindDependencies', 'finddeps');

my $caught = '';
$SIG{__WARN__} = sub {
    $caught = $_[0];
    die($caught)
        if($caught !~ /^WARNING: CPAN::FindDependencies: .*no META.yml/);
};

my @results = finddeps('Acme::Licence');
ok(@results == 1 && $results[0]->name() eq 'Acme::Licence',
   "Modules with no META.yml appear in the list of results");
ok($caught eq "WARNING: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no META.yml\n",
   "... and generate a warning");

$caught = '';
@results = finddeps('DCANTRELL/Acme-Licence-1.0.tar.gz');
ok(@results == 1 && $results[0]->name() eq 'Acme::Licence',
   "Distributions with no META.yml appear in the list of results");
ok($caught eq "WARNING: CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no META.yml\n",
   "... and generate a warning");

$caught = '';
eval { finddeps('Acme::Licence', fatalerrors => 1) };
ok($@ eq "CPAN::FindDependencies: DCANTRELL/Acme-Licence-1.0: no META.yml\n" &&
   $caught eq '',
   "fatalerrors really does make META.yml errors fatal");

$caught = '';
finddeps('Acme::Licence', nowarnings => 1);
ok($caught eq '', "nowarnings suppresses warnings");
