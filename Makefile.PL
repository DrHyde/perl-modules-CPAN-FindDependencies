# $Id: Makefile.PL,v 1.6 2007/08/17 21:26:08 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    PREREQ_PM    => {
        'CPAN'           => 1.52,   # guess
        'YAML'           => 0.61,   # after interface change
        'LWP::UserAgent' => 2.032,
        'Scalar::Util'   => 1.14
    }
);
