#!perl -w
# $Id: FindDependencies.pm,v 1.19 2007/12/01 23:54:12 drhyde Exp $
package CPAN::FindDependencies;

use strict;
use vars qw($p);

use Parse::CPAN::Packages;

{
  open(local *DEVNULL, '>>/dev/null');
  open(local *STDERR, ">&DEVNULL");
  $p = Parse::CPAN::Packages->new(_get02packages());
}

use YAML ();
use LWP::Simple;
use Module::CoreList;
use Scalar::Util qw(blessed);
use CPAN::FindDependencies::Dependency;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '1.1';

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

=item perl

Use this version of perl to figure out what's in core.  If not
specified, it defaults to 5.005.  Three part version numbers
(eg 5.8.8) are supported but discouraged.

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

sub finddeps {
    my($target, %opts) = @_;

    $opts{perl} ||= 5.005;

    die(__PACKAGE__.": $opts{perl} is a broken version number\n")
        if($opts{perl} =~ /[^0-9.]/);

    if($opts{perl} =~ /\..*\./) {
        warn("Three-part version numbers are a bad idea\n")
            if(!$opts{nowarnings});
        my @parts = split(/\./, $opts{perl});
        $opts{perl} = $parts[0] + $parts[1] / 1000 + $parts[2] / 1000000;
    }

    my $module = ($target =~ m!/!) ? _dist2module($target) : $target;

    return _finddeps(
        opts    => \%opts,
        target  => $module,
        version => $p->package($module)->version(),
        seen    => {}
    );
}

sub _module2obj {
    my $module = shift;
    $module = $p->package($module);
    return undef if(!$module);
    return $module->distribution();
}

sub _dist2module {
    my $d = $p->latest_distribution(shift());
    my $module = ($d->contains())[0];
    return ($module, $p->package($module)->version());
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }
sub _getreqs  { return @{_getreqs_uncached(@_)}; }
sub _get02packages { return _get02packages_uncached(); }

sub _get02packages_uncached {
    get('http://www.cpan.org/modules/02packages.details.txt.gz') ||
        die("Couldn't fetch 02packages.details.txt.gz\n");
}

sub incore {
    my %args = @_;
    my $core = $Module::CoreList::version{$args{perl}}{$args{module}};
    return ($core && $core >= $args{version}) ? $core : undef;
}

sub _finddeps_uncached {
    my %args = @_;
    my( $target, $opts, $depth, $version, $seen) = @args{qw(
        target opts depth version seen
    )};
    $depth ||= 0;

    return [] if($target eq 'perl');
    return [
        CPAN::FindDependencies::Dependency->_new(
            depth      => $depth,
            cpanmodule => $target,
            incore     => 1
        )
    ] if(
        incore(
            module => $target,
            perl => $opts->{perl},
            version => $version)
    );

    my $dist = _module2obj($target);

    return [] unless(blessed($dist));

    my $author   = $dist->cpanid();
    my $distname = $dist->distvname();

    return [] if($seen->{$distname});
    $seen->{$distname} = 1;

    my %reqs = _getreqs(
        author   => $author,
        distname => $distname,
        opts     => $opts,
    );

    return [
        CPAN::FindDependencies::Dependency->_new(
            depth      => $depth,
            cpanmodule => $target,
            incore     => 0
        ),
        map {
            _finddeps(
                target  => $_,
                opts    => $opts,
                depth   => $depth + 1,
                seen    => $seen,
                version => $reqs{$_}
            );
        } keys %reqs
    ];
}

sub _getreqs_uncached {
    my %args = @_;
    my($author, $distname, $opts) = @args{qw(
        author distname opts
    )};

    my $yaml = get("http://search.cpan.org/src/$author/$distname/META.yml");
    if(!$yaml) {
        warn('WARNING: '.__PACKAGE__.": $author/$distname: no META.yml\n")
            if(!$opts->{nowarnings});
        return [];
    } else {
        my $yaml = YAML::Load($yaml);
        return [] if(!defined($yaml));
        $yaml->{requires} ||= {};
        $yaml->{build_requires} ||= {};
        return [%{$yaml->{requires}}, %{$yaml->{build_requires}}];
    }
}

1;
