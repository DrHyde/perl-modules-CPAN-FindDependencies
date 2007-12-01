# $Id: Makefile.PL,v 1.9 2007/12/01 23:54:12 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    EXE_FILES    => [qw(
        examples/cpandeps
    )],
    PREREQ_PM    => {
        'Parse::CPAN::Packages' => 2.26,
        'Module::CoreList'      => '2.12',
        'YAML'                  => 0.61,
        'LWP::Simple'           => 1.41,
        'Scalar::Util'          => 1.14
    }
);
