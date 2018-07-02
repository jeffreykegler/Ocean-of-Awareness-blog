#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 12;

use Marpa::R2 4.000;

my $dsl = <<'END_OF_DSL';
lexeme default = latm => 1
:default ::= action => [name,values]
range ::= location
range ::= location COMMA NUMBER
range ::= location COMMA OFFSET
range ::= COMMA location
range ::= location COMMA
range ::= direction

direction ::= DIRECTION

# Note no space is allowed between FILENAME and NUMBER
location    ::= FILE_LINE
location    ::= FUNCNAME
# If just a number is given, the the filename is implied
location    ::= NUMBER
location    ::= method
method      ::= METHOD
location    ::= offset
offset      ::= OFFSET

:discard ~ whitespace
FILE_LINE ~ FILENAME COLON number
COLON ~ ':'
COMMA ~ ','
NUMBER ~ number
OFFSET ~ '+' digits
number ~ digits
digits ~ [\d]+
DIRECTION ~ '+'
DIRECTION ~ '-'
whitespace ~ [\s]+

# Could not find definitions for these lexemes:
# FILENAME, FUNCNAME
# This will do for now
FILENAME ~ name
FUNCNAME ~ name '()'
METHOD ~ name
name ~ name_first_char name_later_chars
name_first_char ~ [A-Za-z_]
name_later_chars ~ name_later_char+
name_later_char ~ [\w]
END_OF_DSL

my @test = (
    [ 'abc', 'OK', [ 'range', [ 'location',  [ 'method', 'abc' ] ] ] ],
    [ '+',   'OK', [ 'range', [ 'direction', '+' ] ] ],
    [ '+9', 'OK', [ 'range', [ 'location', [ 'offset', '+9' ] ] ] ],
    [ 'xyz:3,9', 'OK', [ 'range', [ 'location', 'xyz:3' ], ',', '9' ] ],
    [ ',42',     'OK', [ 'range', ',', [ 'location', '42' ] ] ],
    [ '42,', 'OK', [ 'range', [ 'location', '42' ], ',' ] ],
);

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

TEST: for my $ix (0 .. $#test)
{
    my ($input, $expected_result, $expected_value) = @{$test[$ix]};
    my $i = $ix + 1;
    say "** Test #$i: ", $input;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $result = 'OK';
    my $eval_ok = eval { $value_ref = doit( $recce, \$input ); 1; };
    if ( !$eval_ok ) {
	my $eval_error = $EVAL_ERROR;
	PARSE_EVAL_ERROR: {
	  $result = "Error: $EVAL_ERROR";
	  Test::More::diag($result);
	}
    }
    if ($result ne $expected_result) {
        Test::More::fail(qq{Result of "$input" "$result"; expected "$expected_result"});
    } else {
      Test::More::pass(qq{Result of "$input" matches});
    }
    my $value = '[fail]';
    my $dump_expected = '[fail]';
    if ($value_ref) {
        $value         = Data::Dumper::Dumper($value_ref);
        $dump_expected = Data::Dumper::Dumper(\$expected_value);
    }
    if ($value ne $dump_expected) {
        Test::More::fail(qq{Test of "$input" value was "$value"; expected "$dump_expected"});
    } else {
      Test::More::pass(qq{Value of "$input" matches});
    }
} ## end TEST:

sub doit {
    my ( $recce, $input ) = @_;
    my $input_length = length ${$input};
    my $pos = $recce->read($input);
    if ( $pos < $input_length ) {
	die sprintf qq{Unfinished parse: remainder="%" }, substr(${$input}, $pos);
    }
    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }
    return $value_ref;
}
