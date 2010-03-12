#!perl -w
# $Id: 01-dependencies.t,v 1.9 2007/12/13 15:16:03 drhyde Exp $
use strict;

use Test::More;
plan tests => 2;

use CPAN::FindDependencies 'finddeps';

is_deeply(
    {
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
        } finddeps(
            'CPAN::FindDependencies',
            '02packages' => 't/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1
        )
    },
    {
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0],
        'Scalar::Util' => [1, 'G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz',0],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0],
        'Test::Harness' => [2, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0],
        'File::Spec' => [3, 'K/KW/KWILLIAMS/PathTools-3.25.tar.gz',0],
        'Module::Build' => [4, 'K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz',0],
        'ExtUtils::CBuilder' => [4, 'K/KW/KWILLIAMS/ExtUtils-CBuilder-0.21.tar.gz',0],
        'Test::More' => [2, 'M/MS/MSCHWERN/Test-Simple-0.72.tar.gz',0],
        'File::Temp' => [2, 'T/TJ/TJENNESS/File-Temp-0.19.tar.gz',0]
    },
    "Dependencies calculated OK with default perl"
);
is_deeply(
    {
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0, $_->version()]
        } finddeps(
            'CPAN::FindDependencies',
            '02packages' => 't/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1,
            perl         => 5.008008
        )
    },
    {
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0, 1.1],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1, 2.032],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0, 0.61],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0, 1.9102],
        'Test::Harness' => [2, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0, 2.62],
    },
    "Dependencies calculated OK for perl 5.8.8"
);
