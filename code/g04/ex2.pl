#!perl
# Copyright 2013 Jeffrey Kegler
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

# Based on the 2nd Gang of Four Interpeter example

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use GetOpt::Long;

use Marpa::R2 2.047_012;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME --demo
    $PROGRAM_NAME < file
With --stdin arg, reads expression from standard input.
By default, runs a demo.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $demo_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'demo!' => \$demo_flag, );
usage() if not $getopt_result;

my $input;
GET_INPUT: {
    if ($demo_flag) {

        # eliminate Marpa does precedence
        $input = q{1 and x or y and not x};
    }
    if ( not $demo_flag ) {
        $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
    }
} ## end GET_INPUT:

# Note Go4 ignores precedence
my $rules = <<'END_OF_GRAMMAR';
:default ::= action => ::array bless => ::lhs

:start ::= <boolean expression>
<boolean expression> ::=
       <variable> bless => variable
     | <constant> bless => constant
     | ('(') <boolean expression> (')') action => ::first bless => ::undef
    || 'not' <boolean expression> bless => not_expression
    || <boolean expression> 'and' <boolean expression> bless => and_expression
    || <boolean expression> 'or' <boolean expression> bless => or_expression
<constant> ::= '1' | '0' action => ::first bless => ::undef

<variable> ~ [[:alpha:]] <zero or more word characters>
<zero or more word characters> ~ [\w]*

:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'Boolean_Expression',
        source         => \$rules,
    }
);

sub calculate {
    my ($p_string) = @_;

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar, } );
    my $self = bless { grammar => $grammar }, 'My_Actions';
    $self->{recce}        = $recce;
    local $My_Actions::SELF = $self;

    my $eval_result = eval { $recce->read($p_string); 1 };
    if ( not defined $eval_result ) {

        # Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        say $EVAL_ERROR;
        chomp $eval_error;
        say $recce->show_progress();
        die $self->show_last('C style comment'), "\n", $eval_error, "\n";
    } ## end if ( not defined $eval_result )
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die $self->show_last('C style comment'), "\n",
            "No parse was found, after reading the entire input\n";
    }
    die Data::Dumper::Dumper($value_ref);
    return ${$value_ref};

} ## end sub calculate

my $actual_value = calculate(\$input);
if ( !defined $actual_value ) {
    die 'NO PARSE!';
}

# vim: expandtab shiftwidth=4:
