use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
  NAME         => 'CPAN::FindDependencies',
  META_MERGE => {
    license => 'open_source',
    resources => {
      repository => 'https://github.com/DrHyde/perl-modules-CPAN-FindDependencies',
      bugtracker => 'https://github.com/DrHyde/perl-modules-CPAN-FindDependencies/issues'
    },
  },
  VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
  EXE_FILES    => [qw(
    bin/cpandeps
    bin/cpandeps-diff
  )],
  PREREQ_PM    => {
    'Archive::Tar'          => 0,
    'Archive::Zip'          => 0,
    'File::Path'            => '2.17',
    'File::Type'            => 0,
    'Test::Differences'     => 0,
    'Test::More'            => 0.88, # done_testing
    'Test::Time'            => 0,
    'Parse::CPAN::Packages' => 2.31,
    'Module::CoreList'      => '5.20200920',
    'CPAN::Meta'            => 0,
    'LWP::Protocol::https'  => 6.09,
    'Scalar::Util'          => 1.14,
    'URI::file'             => 4.13,
    'File::Temp'            => 0.19,
    'Capture::Tiny'         => 0.05,
    'Devel::CheckOS'        => 1.52,
    $^O eq 'MSWin32' ? ('Win32::Job' => 0,) : (),
  },
  dist => {
    DIST_CP => 'cp',
    PREOP => "$Config{perlpath} -Mstrict -w shared/doincludes \$(EXE_FILES) \$(TO_INST_PM)"
  }
);

# commented out cos doesn't work on Doze
# package MY;
# sub test {
#     my $text = shift->SUPER::test(@_);
#     $text =~ s/\t(.*test_harness)/\tHARNESS_OPTIONS=j8 $1/;
#     $text;
# }
