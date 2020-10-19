package CPAN::FindDependencies;

use strict;
use warnings;
use vars qw(@indices $VERSION @ISA @EXPORT_OK);

use Archive::Tar;
use Archive::Zip;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use LWP::UserAgent;
use Module::CoreList;
use Scalar::Util qw(blessed);
use CPAN::Meta;
use CPAN::FindDependencies::Dependency;
use CPAN::FindDependencies::MakeMaker qw(getreqs_from_mm);
use Parse::CPAN::Packages;
use URI::file;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(finddeps);

$VERSION = '3.00';

use constant MAXINT => ~0;

=head1 NAME

CPAN::FindDependencies - find dependencies for modules on the CPAN

=head1 SYNOPSIS

    use CPAN::FindDependencies;
    my @dependencies = CPAN::FindDependencies::finddeps("CPAN");
    foreach my $dep (@dependencies) {
        print ' ' x $dep->depth();
        print $dep->name().' ('.$dep->distribution().")\n";
    }

#include shared/incompatible

=head1 HOW IT WORKS

The module uses the CPAN packages index to map modules to distributions and
vice versa, and then fetches distributions' metadata or Makefile.PL files from
a CPAN mirror to determine pre-requisites.  This means that a
working interwebnet connection is required.

=head1 FUNCTIONS

There is just one function, which is not exported by default
although you can make that happen in the usual fashion.

=head2 finddeps

Takes a single compulsory parameter, the name of a module
(ie Some::Module); and the following optional
named parameters:

=over

#include shared/parameters

=back

It returns a list of CPAN::FindDependencies::Dependency objects, whose
useful methods are:

=over

=item name

The module's name;

=item distribution

The distribution containing this module;

=item version

The minimum required version of his module (if specified in the requirer's
pre-requisites list);

=item depth

How deep in the dependency tree this module is;

=item warning

If any warning was generated (even if suppressed) for the module,
it will be recorded here.

=back

Any modules listed as dependencies but which are in the perl core
distribution for the version of perl you specified are suppressed.

These objects are returned in a semi-defined order.  You can be sure
that a module will be immediately followed by one of its dependencies,
then that dependency's dependencies, and so on, followed by the 'root'
module's next dependency, and so on.  You can reconstruct the tree
by paying attention to the depth of each object.

The ordering of any particular module's immediate 'children' can be
assumed to be random - it's actually hash key order.

=head1 SECURITY

If you set C<usemakefilepl> to a true value, this module may download code
from the internet and execute it.  You should think carefully before enabling
that feature.

=head1 BUGS/WARNINGS/LIMITATIONS

You must have web access to L<http://metacpan.org/> and (unless
you tell it where else to look for the index)
L<http://www.cpan.org/>, or have all the data cached locally..
If any
metadata or Makefile.PL files are missing, the distribution's dependencies will
not be found and a warning will be spat out.

Startup can be slow, especially if it needs to fetch the index from
the interweb.

Dynamic dependencies - for example, dependencies that only apply on some
platforms - can't be reliably resolved. They *may* be resolved if you use the
unsafe Makefile.PL, but even that can't be relied on.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in my git repo and
will pass once I've fixed the bug

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPAN-FindDependencies.git>

=head1 SEE ALSO

L<CPAN>

L<http://deps.cpantesters.org/>

L<http://metacpan.org>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2007 - 2019 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 THANKS TO

Stephan Loyd (for fixing problems with some META.yml files)

Alexandr Ciornii (for a patch to stop it segfaulting on Windows)

Brian Phillips (for the code to report on required versions of modules)

Ian Tegebo (for the code to extract deps from Makefile.PL)

Georg Oechsler (for the code to also list 'recommended' modules)

Jonathan Stowe (for making it work through HTTP proxies)

Kenneth Olwing (for support for 'configure_requires')

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

my $default_mirror = 'https://cpan.metacpan.org/';
sub finddeps {
    my($module, @opts) = @_;
    my %opts = (mirrors => []);

    while(@opts) {
        my $optname = shift(@opts);
        my $optarg  = shift(@opts);
        if($optname ne 'mirror' ) {
            $opts{$optname} = $optarg
        } else {
            my($mirror, $packages) = split(/,/, $optarg);
            $mirror = $default_mirror if($mirror eq 'DEFAULT');
            $mirror .= '/' unless($mirror =~ m{/$});
            if($mirror !~ /^https?:\/\//) {
                $mirror = ''.URI::file->new_abs($mirror);
            }
            push @{$opts{mirrors}}, {
                mirror   => $mirror,
                packages => $packages ? $packages : "${mirror}modules/02packages.details.txt.gz"
            };
        }
    }
    unless(@{$opts{mirrors}}) {
        push @{$opts{mirrors}}, {
            mirror   => $default_mirror,
            packages => "${default_mirror}modules/02packages.details.txt.gz"
        }
    }

    $opts{perl} ||= 5.005;
    $opts{maxdepth} ||= MAXINT;

    die(__PACKAGE__.": $opts{perl} is a broken version number\n")
        if($opts{perl} =~ /[^0-9.]/);

    if($opts{perl} =~ /\..*\./) {
        my @parts = split(/\./, $opts{perl});
        $opts{perl} = $parts[0] + $parts[1] / 1000 + $parts[2] / 1000000;
    }

    if(!@indices) {
        local $SIG{__WARN__} = sub {};
        @indices = map {
            Parse::CPAN::Packages->new(_get02packages($_->{packages}))
        } @{$opts{mirrors}}
    }

    my $first_found = _first_found($module, @indices);
    return _finddeps(
        opts    => \%opts,
        target  => $module,
        seen    => {},
        version => ($first_found ? $first_found->version() : 0)
    );
}

sub _first_found {
    my $module = shift;
    my @indices = @_;
    return (map { $_->package($module) } grep { $_->package($module) } @indices)[0];
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
    $module = _first_found($module, @indices);
    return undef if(!$module);
    return $module->distribution();
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }

sub _get02packages {
    my $url = shift;
    if($url !~ /^(file|https?):/) {
        $url = ''.URI::file->new_abs($url);
    }
    _get($url) || die(__PACKAGE__.": Couldn't fetch 02packages index file from $url\n");
}

sub _get {
    my $url = shift;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy();
    $ua->agent(__PACKAGE__."/$VERSION");
    my $response = $ua->get($url);
    if($response->is_success()) {
        return $response->content();
    } else {
        return undef;
    }
}

sub _incore {
    my %args = @_;
    my $core = $Module::CoreList::version{$args{perl}}{$args{module}};
    $core =~ s/_/00/g if($core);
    $args{version} =~ s/_/00/g;
    return ($core && $core >= $args{version}) ? $core : undef;
}

sub _finddeps_uncached {
    my %args = @_;
    my( $target, $opts, $depth, $version, $seen) = @args{qw(
        target opts depth version seen
    )};
    $depth ||= 0;

    return [] if(
        $target eq 'perl' ||
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

    my %reqs = _getreqs(
        author   => $author,
        distname => $distname,
        distfile => $dist->filename(),
        opts     => $opts,
    );
    my $warning = '';
    if($reqs{'-warning'}) {
        $warning = $reqs{'-warning'};
        %reqs = ();
    }

    return [
        CPAN::FindDependencies::Dependency->_new(
            depth      => $depth,
            cpanmodule => $target,
            indices    => \@indices,
            version    => $version || 0,
            ($warning ? (warning => $warning) : ())
        ),
        ($depth != $opts->{maxdepth}) ? (map {
            # print "Looking at $_\n";
            _finddeps(
                target  => $_,
                opts    => $opts,
                depth   => $depth + 1,
                seen    => $seen,
                version => $reqs{$_}
            );
        } sort keys %reqs) : ()
    ];
}

sub _get_file_cached {
    my %args = @_;
    my($src, $cachefile, $post_process, $opts) = @args{qw(src cachefile post_process opts)};
    my $contents;
    if($opts->{cachedir} && -d $opts->{cachedir} && -r $opts->{cachedir}."/$cachefile") {
        open(my $cachefh, $opts->{cachedir}."/$cachefile") ||
            _emitwarning('Error reading '.$opts->{cachedir}."/$cachefile: $!");
        local $/ = undef;
        $contents = <$cachefh>;
        close($cachefh);
    } else {
        $contents = _get($src);
        if($contents && $post_process ) {
            $contents = $post_process->($contents);
        }
        if($contents && $opts->{cachedir} && -d $opts->{cachedir}) {
            open(my $cachefh, '>', $opts->{cachedir}."/$cachefile") ||
                _emitwarning('Error writing '.$opts->{cachedir}."/$cachefile: $!");
            print $cachefh $contents;
            close($cachefh);
        }
    }
    return $contents;
}

sub _getreqs {
    my %args = @_;
    my($author, $distname, $distfile, $opts) = @args{qw(author distname distfile opts)};

    my $meta_file;
    foreach my $source (@{$opts->{mirrors}}) {
        $meta_file = _get_file_cached(
            src => $source->{mirror}."authors/id/".
                   substr($author, 0, 1).'/'.
                   substr($author, 0, 2).'/'.
                   "$author/$distfile",
            post_process => sub {
                # _get_file_cached normally just returns a file, but we're asking
                # it to fetch a an archive from which we want to extract a file,
                # and then cache that extracted file's contents. This function
                # takes a raw tarball (or zip, or ...) and either extract/return
                # a META.json or META.yml's content, or return the empty string
                my $file_data = shift;
                my $meta_file_re = qr/^([^\/]+\/)?META\.(json|yml)/;
                my $rval = undef;

                # We should be able to avoid writing to disk by ...
                # # my $tar = Archive::Tar->new();
                # # $tar->read([string opened as file])
                # # my $zip = Archive::Zip->new();
                # # $zip->readFromFileHandle(...);
                # Unfortunately, while that works for Zip, it doesn't for Tar
                # as that requires an uncompressed stream for ->read(). Balls.
                my $olddir = getcwd();
                my $tempdir = tempdir('CPAN-FindDependencies-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
                chdir($tempdir);
                open(my $fh, '>', $distfile) || die("Can't write $tempdir/$distfile\n");
                binmode($fh); # Windows smells of wee
                print $fh $file_data;
                close($fh);

                if($distfile =~ /\.zip$/i) {
                    my $zip = Archive::Zip->new("$tempdir/$distfile");
                    if(my @members = $zip->membersMatching($meta_file_re)) {
                        $rval = $zip->contents($members[0])
                    }
                } elsif($distfile =~ /\.(tar(\.gz)?|tgz)$/i) {
                    # OMG TEH REPETITION! FIXME!
                    my $tar = Archive::Tar->new("$tempdir/$distfile");
                    if(my @members = grep { /$meta_file_re/ } $tar->list_files()) {
                        $rval = $tar->get_content($members[0])
                    }
                } else {
                    # Assume tar.bz2
                    open(my $fh, '-|', qw(bzip2 -dc), $distfile) || warn("Can't unbzip2 $tempdir/$distfile\n");
                    if($fh) {
                        my $tar = Archive::Tar->new($fh);
                        if(my @members = grep { /$meta_file_re/ } $tar->list_files()) {
                            $rval = $tar->get_content($members[0])
                        }
                    }
                }
                chdir($olddir);
                return $rval;
            },
            cachefile => "$distname.yml",
            opts => $opts
        );
        last if($meta_file);
    }
    if ($meta_file) {
        my $meta_data = eval { CPAN::Meta->load_string($meta_file); };
        if ($@ || !defined($meta_data)) {
            _emitwarning("$author/$distname: failed to parse metadata", %{$opts})
        } else {
            my $reqs = $meta_data->effective_prereqs();
            return %{
                $reqs->merged_requirements(
                    [qw(configure build test runtime)],
                    [
                        'requires',
                        ($opts->{recommended} ? 'recommends' : ()),
                        ($opts->{suggested}   ? 'suggests'   : ())
                    ]
                )->as_string_hash()
            };
        }
    } else {
        _emitwarning("$author/$distname: no metadata", %{$opts});
    }
    
    # We could have failed to parse the META.yml, but we still want to try the Makefile.PL
    if(!$opts->{usemakefilepl}) {
        return ('-warning', 'no metadata');
    } else {
        my $makefilepl = _get_file_cached(
            src => "https://fastapi.metacpan.org/source/$author/$distname/Makefile.PL",
            cachefile => "$distname.MakefilePL",
            opts => $opts
        );
        if($makefilepl) {
            my $result = getreqs_from_mm($makefilepl);
            if ('HASH' eq ref $result) {
                return %{ $result };
            } else {
                _emitwarning("$author/$distname: $result", %{$opts});
                return ('-warning', $result);
            }
        } else {
            _emitwarning("$author/$distname: no metadata nor Makefile.PL", %{$opts});
            return ('-warning', 'no metadata nor Makefile.PL');
        }
    }
}

1;
