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

# Example for blog post on ambiguous languages

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 3;

use Marpa::R2 2.090;

my $dsl = <<'END_OF_DSL';
:default ::= action => ::first
lexeme default = latm => 1
Statements ::= Statement* action => [values]
Statement ::= <Terminated statement>
| <Statement body>
<Terminated statement> ::= <Statement body> ';' action => [values]
<Statement body> ::= <BNF rule> | <lexeme declaration>
<BNF rule> ::= lhs '::=' rhs action => [values]
lhs ::= <symbol name>
rhs ::= symbol* action => [values]
symbol ::= <symbol name> | <single quoted string>
<lexeme declaration> ::= symbol 'matches' <single quoted string> action => [values]

<symbol name> ~ [_[:alpha:]] <symbol characters>
<symbol characters> ~ [_[:alnum:]]*
<single quoted string> ~ ['] <single quoted string chars> [']
<single quoted string chars> ~ [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $calc_lexer   = q{Number matches '\d+'};
my $calc_grammar = <<'END_OF_STRING';
E ::= T '*' F
E ::= T
T ::= F '+' Number
T ::= Number
END_OF_STRING
chomp $calc_grammar;

my $ex1 = join "\n", $calc_lexer,   $calc_grammar, q{};
my $ex2 = join "\n", $calc_grammar, $calc_lexer,   q{};
my $ex3 = join "\n", ( $calc_grammar . q{ ;} ), $calc_lexer, q{};

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

TEST: {
    my $input = \$ex1;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $eval_ok = eval { $value_ref = doit( $recce, $input ); 1; };
    if ( !$eval_ok ) {
        Test::More::fail("Example 1 failed");
        Test::More::diag($EVAL_ERROR);
        last TEST;
    }
    my $result = [ grep {defined} split q{ }, ${$input} ];
    Test::More::is_deeply( $result, flatten($value_ref), 'Example 1' );
} ## end TEST:

TEST: {
    my $expected_error = <<'=== END ===';
Parse of BNF/Scanless source is ambiguous
Length of symbol "Statement" at line 4, column 1 is ambiguous
  Choices start with: T ::= Number
  Choice 1, length=12, ends at line 4, column 12
  Choice 1: T ::= Number
  Choice 2, length=33, ends at line 5, column 20
  Choice 2: T ::= Number\nNumber matches '\\d
=== END ===
    my $input = \$ex2;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $eval_ok = eval { $value_ref = doit( $recce, $input ); 1; };
    if ( !$eval_ok ) {
        Test::More::is( $EVAL_ERROR, $expected_error,
            'Example 2 (ambiguous)' );
        last TEST;
    }
    Test::More::fail('Example 2 parsed -- it should not do so');
} ## end TEST:

TEST: {
    my $input = \$ex3;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $eval_ok = eval { $value_ref = doit( $recce, $input ); 1; };
    if ( !$eval_ok ) {
        Test::More::fail('Example 3 failed');
        Test::More::diag($EVAL_ERROR);
        last TEST;
    }
    my $result = [ grep {defined} split q{ }, ${$input} ];
    Test::More::is_deeply( $result, flatten($value_ref), 'Example 3' );
} ## end TEST:

sub flatten {
    my ($tree) = @_;
    if ( ref $tree eq 'REF' ) { return flatten( ${$tree} ); }
    if ( ref $tree eq 'ARRAY' ) {
        return [ map { @{ flatten($_) } } @{$tree} ];
    }
    return [$tree];
} ## end sub flatten

sub doit {
    my ( $recce, $input ) = @_;
    my $input_length = ${$input};
    my $length_read  = $recce->read($input);
    if ( $length_read != length $input_length ) {
        die "read() ended prematurely\n",
            "  input length = $input_length\n",
            "  length read = $length_read\n",
            "  the cause may be an unexpected event";
    } ## end if ( $length_read != length $input_length )
    if ( $recce->ambiguity_metric() > 1 ) {

        # The calls in this section are experimental as of Marpa::R2 2.090
        my $asf = Marpa::R2::ASF->new( { slr => $recce } );
        say STDERR 'No ASF' if not defined $asf;
        my $ambiguities = Marpa::R2::Internal::ASF::ambiguities($asf);
        my @ambiguities = grep {defined} @{$ambiguities}[ 0 .. 1 ];
        die
            "Parse of BNF/Scanless source is ambiguous\n",
            Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities );
    } ## end if ( $recce->ambiguity_metric() > 1 )

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
} ## end sub doit
