# $Id: Dependency.pm,v 1.5 2007/08/17 21:41:54 drhyde Exp $
#!perl -w
package CPAN::FindDependencies::Dependency;

use strict;

use vars qw($VERSION);

$VERSION = '1.0';

=head1 NAME

CPAN::FindDependencies::Dependency - object representing a module dependency

=head1 SYNOPSIS

    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' ('.$dep->distribution().")\n";
    }

=head1 METHODS

The following read-only accessors are available.  You will note that
there is no public constructor and no mutators.  Objects will be
created by the CPAN::FindDependencies module.

=cut

sub _new {
    my($class, %opts) = @_;
    bless {
        depth      => $opts{depth},
        cpanmodule => $opts{cpanmodule}
    }, $class
}

=head2 name

The name of the module

=cut

sub name { $_[0]->cpanmodule()->id(); }

=head2 distribution

The name of the distribution containing the module

=cut

sub distribution { $_[0]->cpanmodule()->distribution()->id(); }

=head2 depth

How deeply nested this module is in the dependency tree

=cut

sub depth { return $_[0]->{depth} }

=head2 cpanmodule

The CPAN::Module object from which most of this was derived

=cut

sub cpanmodule { return $_[0]->{cpanmodule} }

=head1 BUGS/LIMITATIONS

None known

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in CVS and will
pass once I've fixed the bug

=head1 CVS

L<http://drhyde.cvs.sourceforge.net/drhyde/perlmodules/CPAN-FindDependencies/>

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
