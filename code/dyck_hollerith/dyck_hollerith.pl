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

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;
use Marpa::R2 2.056000;
use English qw( -no_match_vars );

# A Marpa::R2 parser for the Dyck-Hollerith language

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die 'Argument not a number'
        if not Scalar::Util::looks_like_number($repeat);
}

my $dsl = <<'END_OF_DSL';
# The BNF
:start ::= sentence
sentence ::= element
array ::= 'A' <array count> '(' elements ')'
    action => check_array
string ::= ( 'S' <string length> '(' ) text ( ')' )
elements ::= element+
  action => ::array
element ::= string | array

# Declare the places where we pause before
# and after lexemes
:lexeme ~ <string length> pause => after
:lexeme ~ text pause => before

# Declare the lexemes themselves
<array count> ~ [\d]+
<string length> ~ [\d]+
# define <text> as one character of anything, as a stub
# the external scanner determines its actual size and value
text ~ [\d\D]
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
        default_action => '::first',
        source         => \$dsl
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $input;
if ($repeat) {
    $input = "A$repeat("
        . ( 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat ) . ')';
}
else {
    $input = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

my $last_string_length;
my $input_length = length $input;
INPUT:
for (
    my $pos = $recce->read( \$input );
    $pos < $input_length;
    $pos = $recce->resume($pos)
    )
{
    my $lexeme = $recce->pause_lexeme();
    die q{Parse exhausted in front of this string: "},
        substr( $input, $pos ), q{"}
        if not defined $lexeme;
    my ( $start, $lexeme_length ) = $recce->pause_span();
    if ( $lexeme eq 'string length' ) {
        $last_string_length = $recce->literal( $start, $lexeme_length ) + 0;
        $pos = $start + $lexeme_length;
        next INPUT;
    }
    if ( $lexeme eq 'text' ) {
        my $text_length = $last_string_length;
        $recce->lexeme_read( 'text', $start, $text_length );
        $pos = $start + $text_length;
        next INPUT;
    } ## end if ( $lexeme eq 'text' )
    die "Unexpected lexeme: $lexeme";
} ## end INPUT: for ( my $pos = $recce->read( \$input ); $pos < $input_length...)

my $result = $recce->value();
die 'No parse' if not defined $result;
my $received = Data::Dumper::Dumper( ${$result} );

my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
if ( $received eq $expected ) {
    say 'Output matches' or die "say() failed: $ERRNO";
}
else {
    say "Output differs: $received" or die "say() failed: $ERRNO";
}

package My_Actions;

sub new { }

sub check_array {
    my ( undef, undef, $declared_size, undef, $array ) = @_;
    my $actual_size = @{$array};
    warn
        "Array size ($actual_size) does not match that specified ($declared_size)"
        if $declared_size != $actual_size;
    return $array;
} ## end sub check_array

