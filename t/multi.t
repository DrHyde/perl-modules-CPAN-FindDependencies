use strict;
use warnings;

use Test::More;
use Test::Differences;

use CPAN::FindDependencies 'finddeps';

my $private_repo = 't/mirrors/privatemirror';

# just in case they're cached from a previous test run that crashed
unlink(map { "t/cache/multi/$_" } qw(Brewery-1.0.yml Fruit-1.0.yml Fruit-Role-Fermentable-1.0.yml));

eq_or_diff(
    [
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
        } finddeps(
            'Brewery',
            mirror   => $private_repo,
            mirror   => 'DEFAULT,t/cache/multi/02packages.details.txt.gz',
            perl     => '5.28.0',
            cachedir => 't/cache/multi'
        )
    ],
    [
        Brewery         => [0, 'F/FR/FRUITCO/Brewery-1.0.tar.gz', 0],
        'Fruit'         => [1, 'F/FR/FRUITCO/Fruit-1.0.tar.bz2', 0],
        'Capture::Tiny' => [2, 'D/DA/DAGOLDEN/Capture-Tiny-0.48.tar.gz', 0],
        'File::Temp'    => [2, 'E/ET/ETHER/File-Temp-0.2311.tar.gz', 0],
        'Fruit::Role::Fermentable' => [1, 'F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.zip', 0]
    ],
    "Fetch deps from both a private repo $private_repo and a public one"
);

# so they don't confuse matters
unlink(map { "t/cache/multi/$_" } qw(Brewery-1.0.yml Fruit-1.0.yml Fruit-Role-Fermentable-1.0.yml));

done_testing;
