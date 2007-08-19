#!perl -w
# $Id: FindDependencies.pm,v 1.17 2007/08/19 11:58:31 drhyde Exp $
package CPAN::FindDependencies;

use strict;

use CPAN;
use YAML ();
use LWP::UserAgent;
use Scalar::Util qw(blessed);
use Sys::Hostname;  # core in all p5
use CPAN::FindDependencies::Dependency;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '1.02';

=head1 NAME

CPAN::FindDependencies - find dependencies for modules on the CPAN

=head1 SYNOPSIS

    use CPAN::FindDependencies;
    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' ('.$dep->distribution().")\n";
    }

=head1 FUNCTIONS

There is just one function, which is not exported by default
although you can make that happen in the usual fashion.

=head2 finddeps

Takes a single compulsory parameter, the name of a module (ie Some::Module)
or the name of a distribution complete with author and version number (ie
PAUSEID/Some-Distribution-1.234); and the following named parameters:

=over

=item nowarnings

Warnings about modules where we can't find their META.yml, and so
can't divine their pre-requisites, will be suppressed;

=item fatalerrors

Failure to get a module's dependencies will be a fatal error
instead of merely emitting a warning;

=back

It returns a list of CPAN::FindDependencies::Dependency objects, whose
useful methods are:

=over

=item name

The module's name

=item distribution

The distribution containing this module

=item depth

How deep in the dependency tree this module is

=back

=head1 BUGS/WARNINGS/LIMITATIONS

The module assumes that you have a working and configured CPAN.pm,
and that you have web access to L<http://search.cpan.org/>.  It
uses modules' META.yml files to divine dependencies.  If any
META.yml files are missing, the distribution's dependencies will not
be found and a warning will be spat out.

It starts up quite slowly, as it forces CPAN.pm to reload its indexes.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in CVS and will
pass once I've fixed the bug

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 CVS

L<http://drhyde.cvs.sourceforge.net/drhyde/perlmodules/CPAN-FindDependencies/>

=head1 SEE ALSO

L<CPAN>

L<http://cpandeps.cantrell.org.uk/>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This module is free-as-in-speech software, and may be used,
distributed, and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

my $devnull; my $oldfh;
open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
CPAN::HandleConfig->load();
CPAN::Shell::setup_output();
CPAN::Index->reload();
select($oldfh) if($oldfh);

sub finddeps {
    my($target, %opts) = @_;

    my $ua = LWP::UserAgent->new(
        agent => "CPAN-FindDependencies/$VERSION",
        from => hostname()
    );

    my @deps = _finddeps(
        ($target =~ m!/!) ? _dist2module($target) : $target,
        $ua,
        \%opts,
        {}
    );

    return @deps;
}

sub _module2obj {
    my $module = shift;
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    $module = CPAN::Shell->expand("Module", $module);
    select($oldfh) if($oldfh);
    return $module;
}

sub _dist2module {
    my $dist = shift;
    
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    my @mods = sort { $a cmp $b } (CPAN::Shell->expand("Distribution", $dist)->containsmods());
    select($oldfh) if($oldfh);
    return $mods[0] ? $mods[0] : ();
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }
sub _getreqs  { return @{_getreqs_uncached(@_)}; }

sub _finddeps_uncached {
    my($module, $ua, $opts, $visited, $depth) = @_;
    $depth ||= 0;

    $module = _module2obj($module);

    return [] unless(blessed($module) && $module->cpan_file() && $module->distribution());

    my $author = $module->distribution()->author()->id();
    (my $distname = $module->distribution()->id()) =~
        s/^.*\/$author\/(.*)\.(tar\.(gz|bz2?)|zip)$/$1/;

    return [] if($visited->{$distname} || $module->distribution()->isa_perl());
    $visited->{$distname} = 1;

    return [
        CPAN::FindDependencies::Dependency->_new(
            depth => $depth,
            cpanmodule => $module
        ),
        map {
            _finddeps($_, $ua, $opts, $visited, $depth + 1);
        } _getreqs($author, $distname, $ua, $opts)
    ];
}

sub _getreqs_uncached {
    my($author, $distname, $ua, $opts) = @_;

    my $res = $ua->request(HTTP::Request->new(
        GET => "http://search.cpan.org/src/$author/$distname/META.yml"
    ));
    if(!$res->is_success()) {
        if($opts->{fatalerrors}) {
            die(__PACKAGE__.": $author/$distname: no META.yml\n");
        } elsif(!$opts->{nowarnings}) { 
            warn('WARNING: '.__PACKAGE__.": $author/$distname: no META.yml\n");
        }
        return [];
    } else {
        my $yaml = YAML::Load($res->content());
        return [] if(!defined($yaml));
        return [keys %{$yaml->{requires}}];
    }
}

1;
