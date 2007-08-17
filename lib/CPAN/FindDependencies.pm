#!perl -w
# $Id: FindDependencies.pm,v 1.12 2007/08/17 20:38:16 drhyde Exp $
package CPAN::FindDependencies;

use strict;

use Data::Dumper;
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

$VERSION = '1.0';

=head1 NAME

CPAN::FindDependencies - find dependencies for modules on the CPAN

=head1 SYNOPSIS

    use CPAN::FindDependencies;

    print "$module depends on:\n";
    print join("\n", CPAN::FindDependencies::finddeps($module))."\n";

=head1 FUNCTIONS

There is just one function, which is not exported by default
although you can make that happen in the usual fashion.

=head2 finddeps

Takes a single compulsory parameter, the name of a module (ie Some::Module)
or the name of a distribution complete with author and version number (ie
PAUSEID/Some-Distribution-1.234); and the following named parameters:

=over

=item fatalerrors

Failure to get a module's dependencies will be a fatal error instead of merely
emiting a warning

=back

It returns a list of CPAN::FindDependencies::Dependency objects.

=head1 BUGS/WARNINGS/LIMITATIONS

The module assumes that you have a working and configured CPAN.pm,
and that you have web access to L<http://search.cpan.org/>.  It
uses modules' META.yml files to divine dependencies.  If any
META.yml files are missing, the distribution's dependencies will not
be found and a warning will be spat out.

=head1 AUTHOR and FEEDBACK

David Cantrell E<lt>david@cantrell.org.ukE<gt>

I welcome constructive criticism.  If you think you have found a
bug, or would like a new feature, please first make sure you have
read *all* the documentation, let me know what you have tried, and
how the results differ from what you expect or want.

The best bug reports include a test file, which will fail with
the most recent version of the module in CVS
(see http://drhyde.cvs.sourceforge.net/drhyde/perlmodules/) and
will pass when the bug has been fixed.

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 LICENCE and COPYRIGHT

This software is Copyright 2007 David Cantrell.  You may use,
modify and distribute it under the same terms as perl itself.

=cut

1;

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
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    my $mod = CPAN::Shell->expand("Module", $_[0]);
    select($oldfh) if($oldfh);
    return $mod;
}

sub _dist2module {
    my $dist = shift;
    
    my @mods = (CPAN::Shell->expand("Distribution", $dist)->containsmods())[0];
    print Dumper(\@mods);
    return $mods[0] ? $mods[0] : ();
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }
sub _getreqs  { return @{_getreqs_uncached(@_)}; }

sub _finddeps_uncached {
    my($module, $ua, $opts, $visited, $depth) = @_;
    $depth ||= 0;

    $module = _module2obj($module);

    return [] unless(blessed($module) && $module->cpan_file());

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
        } else { 
            warn(__PACKAGE__.": $author/$distname: no META.yml\n");
        }
        return [];
    } else {
        my $yaml = YAML::Load($res->content());
        return [] if(!defined($yaml));
        return [keys %{$yaml->{requires}}];
    }
}

1;
