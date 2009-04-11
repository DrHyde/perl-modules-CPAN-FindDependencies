#!perl -w
use strict;

use Test::More;
plan tests => 3;

use CPAN::FindDependencies 'finddeps';
use Capture::Tiny qw(capture);

my($stdout, $stderr) = capture {
    is_deeply(
        {
            map {
                $_->name() => [$_->depth(), $_->distribution(), $_->warning()]
            } finddeps(
                'Tie::Scalar::Decay',
                '02packages'  => 't/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz',
                cachedir      => 't/cache/Tie-Scalar-Decay-1.1.1',
                nowarnings    => 1,
                usemakefilepl => 1
            )
        },
        {
            'Tie::Scalar::Decay' => [0, 'D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz',undef],
            'Time::HiRes' => [1, 'J/JH/JHI/Time-HiRes-1.9719.tar.gz',undef],
        },
        "Dependencies calculated OK using Makefile.PL"
    );
};

ok($stdout eq '', "Spew to STDOUT was suppressed");
ok($stderr eq '', "Spew to STDERR was suppressed");