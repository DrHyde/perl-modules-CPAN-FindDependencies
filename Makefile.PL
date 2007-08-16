# $Id: Makefile.PL,v 1.5 2007/08/16 22:27:17 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    PREREQ_PM    => {
        'CPAN'           => 1.52,   # guess
        'YAML'           => 0.61,   # after interface change
        'LWP::UserAgent' => 2.032,
    }
);
