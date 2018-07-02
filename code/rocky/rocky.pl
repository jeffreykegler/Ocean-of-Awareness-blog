#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 24;

use Marpa::R2 4.000;

my $dsl = <<'END_OF_DSL';
lexeme default = latm => 1
:default ::= action => [name,start,length,values]
range ::= location
range ::= location COMMA NUMBER
range ::= location COMMA OFFSET
range ::= COMMA location
range ::= location COMMA
range ::= location
range ::= DIRECTION

# Note no space is allowed between FILENAME and NUMBER
location    ::= FILENAME COLON NUMBER
location    ::= FUNCNAME
# If just a number is given, the the filename is implied
location    ::= NUMBER
location    ::= METHOD
location    ::= OFFSET

:discard ~ whitespace
FILE_LINE ::= FILENAME COLON number
COMMA ~ ':'
COMMA ~ ','
NUMBER ~ number
number ~ \d+
OFFSET ~ '+' \d+
DIRECTION ~ '+'
DIRECTION ~ '-'
whitespace ~ [\s]+

# Could not find definitions of FILENAME, FUNCNAME
# This will do for now
FILENAME ~ name
FUNCNAME ~ name
name ~ name_first_char name_later_chars
name_first_char ~ [A-Za-z_]
name_later_chars ~ name_later_char+
name_later_char ~ [\w]
END_OF_DSL

my @test = (
 [ 'abc', 'OK', 'ABC of length 3 starts at 0' ],
 [ 'aabbcc', 'OK', 'ABC of length 6 starts at 0' ],
 [ 'aaabccc', 'OK', 'ABC of length 3 starts at 2' ],
 [ 'aabbcccc', 'OK', 'ABC of length 6 starts at 0' ],
 [ 'aabbccc', 'OK', 'ABC of length 6 starts at 0' ],
 [ 'aaaaabbccc', 'OK', 'ABC of length 6 starts at 3' ],
 [ 'aaaabbbccc', 'OK', 'ABC of length 9 starts at 1' ],
 [ 'abbc', "Too few A's or no B's", '[fail]' ],
 [ 'aabbbccc', "Too few A's or no B's", '[fail]' ],
 [ 'aabbc', "Too few C's", '[fail]' ],
 [ 'aaabbbc', "Too few C's", '[fail]' ],
 [ 'aacc', "Too few A's or no B's", '[fail]' ],
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
    if ($value_ref) {
       $value = find_ABC($value_ref) // '[none]';
    }
    if ($value ne $expected_value) {
        Test::More::fail(qq{Test of "$input" value was "$value"; expected "$expected_value"});
    } else {
      Test::More::pass(qq{Value of "$input" matches});
    }
} ## end TEST:

sub find_ABC {
    my ($tree) = @_;
    my $ref_type = ref $tree;
    return find_ABC(${$tree}) if $ref_type eq 'REF';
    return undef if ref $tree ne 'ARRAY';
    if ($tree->[0] eq 'ABC') {
       my $length = $tree->[2];
       my $start = $tree->[1];
       return "ABC of length $length starts at $start";
    }
    for (my $i = 0; $i <= $#{$tree}; $i++) {
	my $child_value = find_ABC($tree->[$i]);
	return $child_value if $child_value;
    }
    return undef;
}

sub doit {
    my ( $recce, $input ) = @_;
    my $input_length = length ${$input};
    my $pos = $recce->read($input);
    if ( $pos < $input_length ) {
	die qq{Unexpected event: name="$name"};
    }
    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }
    return $value_ref;
}
