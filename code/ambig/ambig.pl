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

use Test::More tests => 2;

use Marpa::R2;

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

my $calc_lexer = q{number matches '\d+'};
my $calc_grammar = <<'END_OF_STRING';
E ::= T '*' F
E ::= T
T ::= F '+' Number
T ::= Number
END_OF_STRING
chomp $calc_grammar;

my $ex1 = join "\n", $calc_lexer, $calc_grammar, q{};
my $ex2 = join "\n", ($calc_grammar . ';'), $calc_lexer, q{};

say $ex1;
say $ex2;

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

for my $input (\$ex1, \$ex2) {
  my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
  doit($recce, $input);
}

sub doit {
	my ($recce, $input) = @_;
	my $input_length = ${$input};
        my $length_read = $recce->read($input);
	if ($length_read != length $input_length) {
	   die "read() ended prematurely\n",
	      "  input length = $input_length\n",
	      "  length read = $length_read\n",
	      "  the cause may be an unexpected event";
	}
        my $value_ref = $recce->value();
	if (!$value_ref) {
                die "input read, but there was no parse";
        }

        return $value_ref;
}
