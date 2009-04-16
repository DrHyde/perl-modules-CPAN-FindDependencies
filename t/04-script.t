#!perl -w
use strict;

use Test::More;
plan tests => 4;

use Devel::CheckOS;
use Capture::Tiny qw(capture);
use Config;

SKIP: {
    skip "Script works but tests don't on Windows.  Dunno why.", 4
        if(Devel::CheckOS::os_is('MicrosoftWindows'));

my($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        Tie::Scalar::Decay
        02packages t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
    )
)};
is_deeply($stderr, '', "no errors reported");
is_deeply($stdout, "*Tie::Scalar::Decay (D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)\n",
    "got Tie::Scalar::Decay right not using Makefile.PL");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        Tie::Scalar::Decay
        02packages t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
        usemakefilepl 1
    )
)};
is_deeply($stdout, 'Tie::Scalar::Decay (D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)
  Time::HiRes (J/JH/JHI/Time-HiRes-1.9719.tar.gz)
', "got Tie::Scalar::Decay right using Makefile.PL");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        CPAN::FindDependencies
        02packages t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz
        cachedir t/cache/CPAN-FindDependencies-1.1/
    )
)};
is_deeply($stdout, 'CPAN::FindDependencies (D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz)
  Scalar::Util (G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz)
  *LWP::UserAgent (G/GA/GAAS/libwww-perl-5.808.tar.gz)
  YAML (I/IN/INGY/YAML-0.66.tar.gz)
  CPAN (A/AN/ANDK/CPAN-1.9205.tar.gz)
    Test::Harness (A/AN/ANDYA/Test-Harness-3.03.tar.gz)
      File::Spec (K/KW/KWILLIAMS/PathTools-3.25.tar.gz)
        Module::Build (K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz)
        ExtUtils::CBuilder (K/KW/KWILLIAMS/ExtUtils-CBuilder-0.21.tar.gz)
    Test::More (M/MS/MSCHWERN/Test-Simple-0.72.tar.gz)
    File::Temp (T/TJ/TJENNESS/File-Temp-0.19.tar.gz)
', "got CPAN::FindDependencies right");

};
