#!/usr/bin/perl)

# An example of an LR-regular choice in
# list comprehension: Boolean guards versus
# generators.

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;
use English qw( -no_match_vars );

use Test::More tests => 1;
use Test::Differences;

use Marpa::R2 4.000;

require "haskell.pm";

my $listComp = <<'EOS';
xss :: [[Integer]]
xss = [ [ 42, 1729, 99 ] ]

ys :: [Integer]
ys = [ 42, 1729, 99 ]

list = [ x | [x, 1729,
                -- INSERT HERE
                99
             ] <- xss ]

list2 = [ x | [x, 1729, 99] <- xss,
               [x, 1729,
                  99
               ] == ys,
             [ 42, 1729, 99 ] <- xss
             ]

main = do
    putStrLn (show list)
    putStrLn (show list2)
EOS

my $insertLine = <<'EOS';
                1, 2, 3, 4, 5, 6, 7, 8, 9,
EOS

my $insertion = ($insertLine x 100);
$listComp =~ s/^ [ -]* INSERT [ ] HERE [^\n]* $/$insertion/xms;

local $main::TRACE_ES = 0;
local $main::DEBUG = 0;
my $inputRef = \$listComp;

say STDERR '===';
say STDERR $listComp;
say STDERR '===';

my ($result, $valueRef) = MarpaX::R2::Haskell::parse($inputRef);
if ( $result ne 'OK' ) {
    Test::More::fail(qq{Result was "$result", not OK});
    return;
}
Test::More::pass(qq{Result is OK});
