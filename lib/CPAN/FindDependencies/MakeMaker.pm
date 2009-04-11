#!perl -w
# TODO	Figure out how to recover from fatal errors inside the 'eval $MakefilePL' call.

package CPAN::FindDependencies::MakeMaker;

use strict;
use vars qw($p $VERSION @ISA @EXPORT_OK);

use Fatal qw( open close );

my $DEBUG = 0; # For dev use

my $MK_FH; # File handle to scalar $makefile_str

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( getreqs_from_mm );

$VERSION = '0.1';

=head1 NAME

CPAN::FindDependencies::MakeMaker - retrieve dependencies specified in Makefile.PL's

=head1 SYNOPSIS

Dependencies are also specified in Makefile.PL files used with the ExtUtils::MakeMaker module.

=head1 FUNCTIONS

=over

=item getreqs_from_mm

Expects the contents of a Makefile.PL as a string.

Returns a hash reference of the form:

	{
		Module::Name => 0.1,
		...
		Last::Module => 9.0,
	}

=back

=cut

sub getreqs_from_mm {
	my $MakefilePL = shift;

	my $makefile_str;
	my $mm_stdout = '';
	my $mm_stderr = '';
	open $MK_FH, ">", \$makefile_str;

	{
		
		local (*STDOUT, *STDERR);
		open STDOUT, ">", \$mm_stdout;
		open STDERR, ">", \$mm_stderr;
	
		require ExtUtils::MakeMaker;
		
		no warnings qw{redefine once}; # For parse_version, flush

		# This is to keep MM from trying to eval modules that aren't there, and thus dying.
		#	-I don't want to have to download/gunzip distributions just to parse the Makefile.
		*ExtUtils::MM_Unix::parse_version = sub { };
	
		# This override is a slightly modified copy of the original
		# whose purpose is to print the would-be Makefile into a scalar filehandle.
		# 	We'll then parse that Makefile for prereqs.
		*ExtUtils::MakeMaker::flush = \&_flush_to_mk_fh;

		use warnings qw{redefine once};

		eval $MakefilePL;
	
		close STDOUT;
		close STDERR;
	}
	
	if ( $DEBUG ) {
		warn "Problems extracting prereqs from Makefile.PL:\n$mm_stdout"
			unless $mm_stdout =~ /Looks good/;
		warn "ExtUtils::MakeMaker Warnings:\n$mm_stderr"
			if $mm_stderr =~ /Warning/;
	}

	return _parse_makefile( $makefile_str );
}

sub _parse_makefile {
	my $makefile_str = shift;
	return "Unable to get Makefile" unless defined $makefile_str;
	my %required_version_for;
	my @prereq_lines = grep { /^\s*#.*PREREQ/ } split /\n/, $makefile_str;
	for my $line ( @prereq_lines ) {
		if ( $line =~ /PREREQ_PM \s+ => \s+ \{ \s* (.*) \s* \} $/x ) {
			no strict 'subs';
			%required_version_for = eval "( $1 )";
			return "Failed to eval $1: $@" if $@;
			use strict 'subs';
		} else {
			return "Unrecognized PREREQ line in Makefile.PL:\n$line";
		}
	}
	return \%required_version_for;
}

sub _flush_to_mk_fh {
    my $self = shift;

    my $finalname = $self->{MAKEFILE};
    print STDOUT "Writing $finalname for $self->{NAME}\n";

	no warnings 'once'; # for Is_VMS
    unlink($finalname, "MakeMaker.tmp", $ExtUtils::MakeMaker::Is_VMS ? 'Descrip.MMS' : ());
	use warnings 'once';

    for my $chunk (@{$self->{RESULT}}) {
		#print "$chunk\n";
        print $MK_FH "$chunk\n";
    }

    my %keep = map { ($_ => 1) } qw(NEEDS_LINKING HAS_LINK_CODE);

    if ($self->{PARENT} && !$self->{_KEEP_AFTER_FLUSH}) {
        foreach (keys %$self) { # safe memory
            delete $self->{$_} unless $keep{$_};
        }
    }

    system("$Config::Config{eunicefix} $finalname") unless $Config::Config{eunicefix} eq ":";
};

=head1 BUGS/LIMITATIONS

Makefile.PLs that have external dependencies/calls that can fatally die will
not be able to be successfully parsed and then scanned for dependencies, e.g.
libwww-perl.5808.

=head1 SEE ALSO

L<CPAN::FindDepdendencies>

L<CPAN>

L<http://cpandeps.cantrell.org.uk/>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This module is free-as-in-speech software, and may be used,
distributed, and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
