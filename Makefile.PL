use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    PREREQ_PM    => {
        'CPAN'           => 1.52,   # guess
        'YAML'           => 0.61,   # after interface change
        'LWP::UserAgent' => 2.032
    }
);
