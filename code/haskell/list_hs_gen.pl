#!/usr/bin/perl

# Generate example Haskell for list comprehension
# test of Boolean guards versus
# generators.

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );

use Marpa::R2 4.000;

my $count_arg = pop @ARGV;
my $count = $count_arg + 0;
die "count = $count_arg" if $count <= 0;

my $listComp1 = <<'EOS';
module Try () where

xss :: [[Integer]]
xss = [ [ 1, 2, 3 ] ]

ys :: [Integer]
ys = [ 42, 8675309, 1729 ]

list = [ x | [x, 2, 3, 4,
                5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8,
EOS

my $listComp2 = <<'EOS';
                99
             ] <- xss ]

list2 = [ x | [x] <- xss,
               [x, 2, 3, 4,
                  5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8,
EOS

my $listComp3 = <<'EOS';
                  99
               ] == ys,
             [1, 2, 3] <- xss
             ]
EOS

my $listCompVary = <<'EOS';
                  5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8,
EOS

print $listComp1;
print ($listCompVary x $count);
print $listComp2;
print ($listCompVary x $count);
print $listComp3;

