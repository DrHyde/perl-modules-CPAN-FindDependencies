use strict;
use warnings;

use CPAN::FindDependencies qw(finddeps);

use Test::More;
use Test::Differences;

use Capture::Tiny qw(capture);
use Config;
use File::Path qw(remove_tree);

$ENV{CPANDEPS_DIFF_DIR} = '.';
remove_tree('.cpandeps-diff');
END {
    remove_tree('.cpandeps-diff') if(Test::More->builder()->is_passing());
}

my @default_cmd = (
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    'blib/script/cpandeps-diff',
    qw(perl 5.30.3)
);

my @mirror = qw(mirror t/mirrors/privatemirror);

my($stdout, $stderr) = capture { system( @default_cmd, 'list') };
eq_or_diff($stdout, '', "Starting with an empty db");

note("Try to add without saying what to add");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, 'add') };
eq_or_diff($stdout, '', "Nothing on STDOUT");
like($stderr, qr/You must provide an argument to 'add'/, "STDERR as expected");

note("Try to add properly");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Brewery)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");
note("Same again");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Brewery)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Add another module");
($stdout, $stderr) = capture { system( @default_cmd, @mirror, qw(add Fruit)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("List modules");
($stdout, $stderr) = capture { system( @default_cmd, qw(list)) };
eq_or_diff($stdout, join("\n", qw(Brewery Fruit))."\n", "Got expected list");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Report (nothing should have changed)");
($stdout, $stderr) = capture { system( @default_cmd, @mirror) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

(my $v = $^V) =~ s/^v//;
open(my $fh, '>', ".cpandeps-diff/$v/Brewery") || die("Can't fiddle with cached deps: $!\n");
print $fh join("\n",
    "F/FR/FRUITCO/Fruit-1.1.tar.gz",
    "P/PR/PROTEIN/Dead-Rat-94.tar.gz",
    "P/PR/PROTEIN/Human-Toe-1.5.tar.gz"
);
close($fh);

note("Report (there were changes)");
($stdout, $stderr) = capture { system( @default_cmd, @mirror) };
eq_or_diff($stdout,
"Differences found in dependencies for Brewery:
+--+-----------------------------------+--+---------------------------------------------+
* 1|F/FR/FRUITCO/Fruit-1.1.tar.gz      * 1|F/FR/FRUITCO/Fruit-1.0.tar.bz2               *
* 2|P/PR/PROTEIN/Dead-Rat-94.tar.gz\\n  * 2|F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.zip  *
* 3|P/PR/PROTEIN/Human-Toe-1.5.tar.gz  *  |                                             |
+--+-----------------------------------+--+---------------------------------------------+
", "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("Remove module from db");
($stdout, $stderr) = capture { system( @default_cmd, qw(rm Fruit)) };
eq_or_diff($stdout, '', "Nothing on STDOUT");
eq_or_diff($stderr, '', "Nothing on STDERR");

note("List modules again");
($stdout, $stderr) = capture { system( @default_cmd, qw(list)) };
eq_or_diff($stdout, "Brewery\n", "Got expected list");

done_testing();
