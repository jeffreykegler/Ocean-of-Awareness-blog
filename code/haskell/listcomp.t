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

use Test::More tests => 2;
use Test::Differences;

use Marpa::R2 4.000;

require "haskell.pm";

my $listComp = <<'EOS';
xss :: [[Integer]]
xss = [ [ 42, 1729, 99 ] ]

ys :: [Integer]
ys = [ 42, 1729, 99 ]

list = [ x | [x, 1729,
                -- insert more here
                99
             ] <- xss ]

list2 = [ x | [x, 1729, 99] <- xss,
               [x, 1729,
                  -- insert more here
                  99
               ] == ys,
             [ 42, 1729, 99 ] <- xss
             ]

main = do
    putStrLn (show list)
    putStrLn (show list2)
EOS

my $listComp_ast  =  []
  ;

my $listComp_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($listComp_ast) );

local $main::DEBUG = 1;

doTest( \$listComp, $listComp_expected );
$main::DEBUG = 0;

sub doTest {
    my ($inputRef, $expected_value ) = @_;
    my ($result, $valueRef) = MarpaX::R2::Haskell::parse($inputRef);
    if ( $result ne 'OK' ) {
        Test::More::fail(qq{Result was "$result", not OK});
        Test::More::fail(qq{No value test, because result was not OK});
        return
    }
    Test::More::pass(qq{Result is OK});
    my $value = '[fail]';
    if ($valueRef) {

    # say "===\n", Data::Dumper::Dumper(
    # MarpaX::R2::Haskell::pruneNodes($valueRef) ), "===\n";

        $value = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($$valueRef) );
    }
    TODO: {
      local $TODO = 'NYI';
      Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
    }
}
