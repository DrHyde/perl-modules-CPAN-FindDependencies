use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Tie::STDOUT',
    VERSION_FROM => 'lib/CPAN/FindDependencies',
    PREREQ_PM    => {
        'CPAN'           => 1.52,   # guess
        'YAML'           => 0.61,   # after interface change
        'LWP::UserAgent' => 2.033
    }
);
