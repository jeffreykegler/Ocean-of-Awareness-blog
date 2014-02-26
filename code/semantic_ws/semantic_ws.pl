#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Example for blog post

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;

use Marpa::R2;

my $dsl = <<'END_OF_DSL';
:default ::= action => ::first
:start ::= Expression
Expression ::= Term
Term ::=
      Factor
    | Term '+' Term action => do_add
Factor ::=
      Number
    | Factor '*' Factor action => do_multiply
Number ~ digits
digits ~ [\d]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $dsl_scrambled = <<'END_OF_DSL';
:default ::= action => ::first :start ::= Expression Expression ::= Term
Term ::= Factor | Term '+' Term action => do_add Factor ::= Number |
Factor '*' Factor action => do_multiply Number ~ digits digits ~
[\d]+ :discard ~ whitespace whitespace ~ [\s]+
END_OF_DSL

for my $source ( $dsl, $dsl_scrambled ) {
    my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
    my $recce = Marpa::R2::Scanless::R->new(
        { grammar => $grammar, semantics_package => 'My_Actions' } );
    my $input = '42 * 1 + 7';
    $recce->read( \$input );

    my $value_ref = $recce->value;
    my $value = $value_ref ? ${$value_ref} : 'No Parse';

    Test::More::is( $value, 49, 'Landing page synopsis value' );
} ## end for my $source ( $dsl, $dsl_scrambled )

sub My_Actions::do_add {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 + $t2;
}

sub My_Actions::do_multiply {
    my ( undef, $t1, undef, $t2 ) = @_;
    return $t1 * $t2;
}

# vim: expandtab shiftwidth=4:
