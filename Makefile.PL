# $Id: Makefile.PL,v 1.11 2007/12/13 15:16:03 drhyde Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    EXE_FILES    => [qw(
        examples/cpandeps
    )],
    PREREQ_PM    => {
        'Parse::CPAN::Packages' => 2.26,
        'Module::CoreList'      => 2.12,
        'YAML'                  => 0.61,
        'LWP::Simple'           => 1.41,
        'Scalar::Util'          => 1.14,
        'URI::file'             => 4.13,
        'File::Temp'            => 0.19,
        'Capture::Tiny'         => 0.05,
        'Devel::CheckOS'        => 1.52,
    }
);
