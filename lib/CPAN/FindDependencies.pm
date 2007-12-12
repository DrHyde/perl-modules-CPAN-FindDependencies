#!perl -w
# $Id: FindDependencies.pm,v 1.22 2007/12/12 23:57:35 drhyde Exp $

package CPAN::FindDependencies;

use strict;
use vars qw($p $VERSION @ISA @EXPORT_OK);

use YAML ();
use LWP::Simple;
use Module::CoreList;
use Scalar::Util qw(blessed);
use CPAN::FindDependencies::Dependency;
use Parse::CPAN::Packages;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '1.99_01';

use constant DEFAULT02PACKAGES => 'http://www.cpan.org/modules/02packages.details.txt.gz';

=head1 NAME

CPAN::FindDependencies - find dependencies for modules on the CPAN

=head1 SYNOPSIS

    use CPAN::FindDependencies;
    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' ('.$dep->distribution().")\n";
    }

=head1 HOW IT WORKS

The module uses the CPAN packages index to map modules to distributions
and vice versa, and then fetches distributions' META.yml files from
C<http://search.cpan.org/> to determine pre-requisites.  This means
that a working interwebnet connection is required.

=head1 FUNCTIONS

There is just one function, which is not exported by default
although you can make that happen in the usual fashion.

=head2 finddeps

Takes a single compulsory parameter, the name of a module
(ie Some::Module); and the following optional
named parameters:

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

=item 02packages

The location of CPAN.pm's C<02packages.details.txt.gz> file as a URL.
To specify a local file, say something like
C<file:///home/me/minicpan/02packages.details.txt.gz>.  This defaults
to fetching it from a public CPAN mirror.  The file is fetched once,
when the module loads.

This is a URL because it is passed straight through to
C<LWP::Simple::get>.

=item cachedir

A directory to use for caching.  It defaults to no caching.  Even if
caching is turned on, this is only for META.yml files.  02packages is
not cached - if you want to read that from a local disk, see the
C<02packages> option.

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

You must have web access to L<http://search.cpan.org/> and (unless
you tell it where else to look for the index)
L<http://www.cpan.org/>.
If any
META.yml files are missing, the distribution's dependencies will not
be found and a warning will be spat out.

Startup can be slow, especially if it needs to fetch the index from
the interweb.

The location of a local 02packages file is specified as a URL because
of laziness.  Patches to translate from local paths to the necessary
URL would be most welcome.

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

L<http://search.cpan.org>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This module is free-as-in-speech software, and may be used,
distributed, and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub finddeps {
    my($module, %opts) = @_;

    $opts{perl} ||= 5.005;

    die(__PACKAGE__.": $opts{perl} is a broken version number\n")
        if($opts{perl} =~ /[^0-9.]/);

    if($opts{perl} =~ /\..*\./) {
        _emitwarning(
            "Three-part version numbers are a bad idea",
            %opts
        );
        my @parts = split(/\./, $opts{perl});
        $opts{perl} = $parts[0] + $parts[1] / 1000 + $parts[2] / 1000000;
    }

    if(!$p) {
        local $SIG{__WARN__} = sub {};
        $p = Parse::CPAN::Packages->new(_get02packages($opts{'02packages'}));
    }

    return _finddeps(
        opts    => \%opts,
        target  => $module,
        seen    => {},
        version => ($p->package($module) ? $p->package($module)->version() : 0)
    );
}

sub _emitwarning {
    my($msg, %opts) = @_;
    $msg = __PACKAGE__.": $msg\n";
    if(!$opts{nowarnings}) {
        if($opts{fatalerrors} ) {
            die('FATAL: '.$msg);
        } else {
            warn('WARNING: '.$msg);
        }
    }
}

sub _module2obj {
    my $module = shift;
    $module = $p->package($module);
    return undef if(!$module);
    return $module->distribution();
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }

sub _get02packages {
    get(shift() || DEFAULT02PACKAGES) ||
        die(__PACKAGE__.": Couldn't fetch 02packages index file\n");
}

sub _incore {
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
            incore     => 1,
            p          => $p
        )
    ] if(
        _incore(
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

    my %reqs = @{_getreqs(
        author   => $author,
        distname => $distname,
        opts     => $opts,
    )};
    my $warning = '';
    if($reqs{'-warning'}) {
        $warning = $reqs{'-warning'};
        %reqs = ();
    }

    return [
        CPAN::FindDependencies::Dependency->_new(
            depth      => $depth,
            cpanmodule => $target,
            incore     => 0,
            p          => $p,
            ($warning ? (warning => $warning) : ())
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

sub _getreqs {
    my %args = @_;
    my($author, $distname, $opts) = @args{qw(
        author distname opts
    )};

    my $yaml;
    if(
        $opts->{cachedir} &&
        -d $opts->{cachedir} &&
        -r $opts->{cachedir}."/$distname.yml"
    ) {
        open(my $yamlfh, $opts->{cachedir}."/$distname.yml") ||
            _emitwarning('Error reading '.$opts->{cachedir}."/$distname.yml: $!");
        local $/ = undef;
        $yaml = <$yamlfh>;
        close($yamlfh);
    } else {
        $yaml = get("http://search.cpan.org/src/$author/$distname/META.yml");
        if($yaml && $opts->{cachedir} && -d $opts->{cachedir}) {
            open(my $yamlfh, '>', $opts->{cachedir}."/$distname.yml") ||
                _emitwarning('Error writing '.$opts->{cachedir}."/$distname.yml: $!");
            print $yamlfh $yaml;
            close($yamlfh);
        }
    }

    if(!$yaml) {
        _emitwarning("$author/$distname: no META.yml", %{$opts});
        return ['-warning', 'no META.yml'];
    } else {
        my $yaml = eval { YAML::Load($yaml); };
        return ['-warning', 'no META.yml'] if($@ || !defined($yaml));
        $yaml->{requires} ||= {};
        $yaml->{build_requires} ||= {};
        return [%{$yaml->{requires}}, %{$yaml->{build_requires}}];
    }
}

1;
