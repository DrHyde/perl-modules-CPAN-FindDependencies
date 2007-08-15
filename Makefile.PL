use ExtUtils::MakeMaker;
use CPAN;

my $dist = eval {
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    my $dist = CPAN::Shell->expand("Module", "CPAN")->{RO}->{CPAN_FILE};
    select($oldfh) if($oldfh);
    $dist;
};

die("Your CPAN.pm is incompatible with CPAN::FindDependencies or broken\n$@\n")
    if($@ || !$dist);

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    PREREQ_PM    => {
        'CPAN'           => 1.52,   # guess
        'YAML'           => 0.61,   # after interface change
        'LWP::UserAgent' => 2.032,
    }
);
