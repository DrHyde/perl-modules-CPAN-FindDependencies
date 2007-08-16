use CPAN;
use Test::More;

my $dist = eval {
    my $devnull; my $oldfh;
    open($devnull, '>>/dev/null') && do { $oldfh = select($devnull) };
    my $dist = CPAN::Shell->expand("Module", "CPAN")->{RO}->{CPAN_FILE};
    select($oldfh) if($oldfh);
    $dist;
};

if($@ || !$dist) {
    plan skip_all => "Need functional CPAN.pm.  Check permissions";
    exit;
}

1;
