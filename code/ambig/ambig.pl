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

use Test::More tests => 2;

use Marpa::R2 2.090;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1
Statements ::= Statement*
Statement ::= <Terminated statement>
| <Statement body>
<Terminated statement> ::= <Statement body> ';'
<Statement body> ::= <BNF rule> | <lexeme declaration>
<BNF rule> ::= lhs '::=' rhs
lhs ::= <symbol name>
rhs ::= symbol*
symbol ::= <symbol name> | <single quoted string>
<lexeme declaration> ::= symbol 'matches' <single quoted string>

<symbol name> ~ [_[:alpha:]] <symbol characters>
<symbol characters> ~ [_[:alnum:]]*
<single quoted string> ~ ['] <single quoted string chars> [']
<single quoted string chars> ~ [^'\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]+
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my $calc_lexer = q{Number matches '\d+'};
my $calc_grammar = <<'END_OF_STRING';
E ::= T '*' F
E ::= T
T ::= F '+' Number
T ::= Number
END_OF_STRING
chomp $calc_grammar;

my $ex1 = join "\n", $calc_lexer, $calc_grammar, q{};
my $ex2 = join "\n", $calc_grammar, $calc_lexer, q{};
my $ex3 = join "\n", ($calc_grammar . ';'), $calc_lexer, q{};


my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

for my $input (\$ex1, \$ex2, \$ex3) {
  say ${$input};
  my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar
     # , trace_terminals => 99
  } );
  my $eval_ok = eval { my $value_ref = doit($recce, $input); 1; };
  if (!$eval_ok) {
     say $EVAL_ERROR;
  }
  # say Data::Dumper::Dumper($value_ref);
}

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
            Marpa::R2::Internal::ASF::ambiguities_show( $asf, \@ambiguities )
        ;
    } ## end if ( $recce->ambiguity_metric() > 1 )

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
} ## end sub doit
