# $Id: Makefile.PL,v 1.7 2007/08/19 00:44:01 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    PREREQ_PM    => {
        'CPAN'           => 1.9102,
        'YAML'           => 0.61,
        'LWP::UserAgent' => 2.032,
        'Scalar::Util'   => 1.14
    }
);
