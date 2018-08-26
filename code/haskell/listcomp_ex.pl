#!/usr/bin/perl)

# An example of an LR-regular choice in
# list comprehension: Boolean guards versus
# generators.

# This example is for a specific blog post,
# and is not to be included in the test
# suite.

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

list = [ x | [x, 1729,
                1, 2, 3,
                99
             ] <- xss ]

EOS

# This trace level above that allowed in test suite
local $main::TRACE_ES = 2;

local $main::DEBUG = 0;
my $inputRef = \$listComp;

my ($result, $valueRef) = MarpaX::R2::Haskell::parse($inputRef);
if ( $result ne 'OK' ) {
    Test::More::fail(qq{Result was "$result", not OK});
    return;
}
Test::More::pass(qq{Result is OK});
