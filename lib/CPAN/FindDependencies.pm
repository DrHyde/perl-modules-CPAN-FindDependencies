package CPAN::FindDependencies;

use strict;
use warnings;

use CPAN;
use YAML ();
use LWP::UserAgent;
use Sys::Hostname;  # core in all p5

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

Takes a single parameter, the name of a module (ie Some::Module)
or the name of a distribution complete with version number (ie
Some-Distribution-1.234).

If passed a module name, it returns a list of modules on which that
module depends.  If passed a distribution name, it returns a list of
distributions instead.

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
    my $target = shift;

    my $ua = LWP::UserAgent->new(
        agent => "CPAN-FindDependencies/$VERSION",
        from => hostname()
    );

    my @deps = _finddeps(
        ($target =~ /::/) ? $target : _dist2module($target),
        $ua,
        {}
    );
}

# FIXME make CPAN.pm silent
sub _module2dist { CPAN::Shell->expand("Module", $_[0]); }

sub _dist2module {
    die("Don't yet know how to turn a dist into a module name\n");
}

# FIXME make these memoise, maybe to disk
sub _finddeps { return @{_finddeps_uncached(@_)}; }
sub _getreqs  { return @{_getreqs_uncached(@_)}; }

sub _finddeps_uncached {
    my($module, $ua, $distsvisited) = @_;
    $distsvisited ||= {};

    my $dist = _module2dist($module);

    my $author = $dist->{RO}->{CPAN_USERID};
    my $distname = $dist->{RO}->{CPAN_FILE};

    $distname =~ s!(^.*/|(\.tar\.gz|\.zip)$)!!g;

    return [] if($distsvisited->{$distname} || $module eq 'perl' || $distname =~ /^perl/);
    $distsvisited->{$distname} = 1;

    return [
        $dist,
        map {
            _finddeps($_, $ua, $distsvisited);
        } _getreqs($author, $distname, $ua)
    ];
}

sub _getreqs_uncached {
    my($author, $distname, $ua) = @_;

    my $res = $ua->request(HTTP::Request->new(
        GET => "http://search.cpan.org/src/$author/$distname/META.yml"
    ));
    if(!$res->is_success()) {
        warn(__PACKAGE__.": $author/$distname: no META.yml\n");
        return [];
    } else {
        my $yaml = YAML::Load($res->content());
        return [] if(!defined($yaml));
        return [keys %{$yaml->{requires}}];
    }
}

1;
