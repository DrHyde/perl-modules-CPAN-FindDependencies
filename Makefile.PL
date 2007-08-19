# $Id: Makefile.PL,v 1.8 2007/08/19 11:57:11 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    EXE_FILES    => [qw(
        examples/cpandeps
    )],
    PREREQ_PM    => {
        'CPAN'           => 1.9102,
        'YAML'           => 0.61,
        'LWP::UserAgent' => 2.032,
        'Scalar::Util'   => 1.14
    }
);
