# $Id: Makefile.PL,v 1.11 2007/12/13 15:16:03 drhyde Exp $
use ExtUtils::MakeMaker;
use Config;

use lib::CPAN::FindDependencies;

WriteMakefile(
    NAME         => 'CPAN::FindDependencies',
    VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
    EXE_FILES    => [qw(
        examples/cpandeps
    )],
    PREREQ_PM    => {
        'Parse::CPAN::Packages' => 2.31,
        'Module::CoreList'      => 2.12,
        # 'YAML'                  => 0.61,
        'YAML::Tiny'            => 1.36,
        'LWP::Simple'           => 1.41,
        'Scalar::Util'          => 1.14,
        'URI::file'             => 4.13,
        'File::Temp'            => 0.19,
        'Capture::Tiny'         => 0.05,
        'Devel::CheckOS'        => 1.52,
    },
    dist => {
        PREOP => join(' ', split(/[\n\r]+/, qq[
	    $Config{perlpath} -e '
	        undef \$\$/;
	        foreach my \$\$file (map { "CPAN-FindDependencies-$CPAN::FindDependencies::VERSION/".\$\$_ } qw(\$(EXE_FILES) \$(TO_INST_PM))) {
		    my \$\$contents = <FOO>;
		    close(FOO);

		    \$\$contents =~ s/\\#include (.*)/
			print "Including \$\$1\\n";
		        open(FOO, \$\$1);
			\$\$include = <FOO>;
			close(FOO);
			\$\$include;
		    /ge;

		    \\# open(FOO, ">\$\$file");
		    \\# print FOO \$\$contents;
		    \\# close(FOO);
		    print \$\$contents;
		}
	    '
	]))
    }
);

package MY;
sub test {
    my $text = shift->SUPER::test(@_);
    $text =~ s/\t(.*test_harness)/\tHARNESS_OPTIONS=j8 $1/;
    $text;
}
