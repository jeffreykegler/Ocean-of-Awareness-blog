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
S ::= statements
statements ::= statement*
statement ::= var '=' boolean
statement ::= label ':'
statement ::= goto
statement ::= if_statement
statement ::= bytecodes
if_statement ::= 'if':i var 'then':i statements 'end':i
if_statement ::= 'if':i var 'then':i statements 'else':i statements 'end':i
:discard ~ whitespace
whitespace ~ [\s]
boolean ~ 'true'
boolean ~ 'false'
label ~ name
var ~ name
name ~ first_char later_chars
first_char ~ [_a-zA-Z]
later_chars  ~ [_a-zA-Z0-9]+
:lexeme ~ bytecodes pause => before event => 'before bytecodes'
:lexeme ~ goto pause => before event => 'before goto'
bytecodes ~ [\d\D] # dummy -- procedural logic reads <goto>
goto ~ 'goto':i # dummy -- procedural logic reads <goto>
END_OF_DSL

my $test = <<'EOS';
cond1 = true
cond2 = false
if cond1 then
    LOAD 42
    LOAD 1792
    BUILD_LIST 2
if cond2 then
    LOAD 1
    LOAD 2
    BUILD_LIST 2
    GOTO BYTECODE_88
    LOAD 2
    BUILD_LIST 1
else
    LOAD 1
    LOAD 42
    LOAD 1792
    BUILD_LIST 2
    LOAD 711
    BUILD_LIST 3
else
    GOTO FINISH
end
FINISH:
EOS

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

{
    my $expected_result = '';
    my $expected_value = '';
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $result = 'OK';
    my $eval_ok = eval { $value_ref = doit( $recce, \$test ); 1; };
    if ( !$eval_ok ) {
	my $eval_error = $EVAL_ERROR;
	PARSE_EVAL_ERROR: {
	  $result = "Error: $EVAL_ERROR";
	  Test::More::diag($result);
	}
    }
    if ($result ne $expected_result) {
        Test::More::fail(qq{Result was "$result"; expected "$expected_result"});
    } else {
      Test::More::pass(qq{Result matches});
    }
    my $value = '[fail]';
    if ($value_ref) {
       $value = Data::Dumper::Dumper($value_ref);
    }
    if ($value ne $expected_value) {
        Test::More::fail(qq{Test of value was "$value"; expected "$expected_value"});
    } else {
      Test::More::pass(qq{Value matches});
    }
} ## end TEST:

sub doit {
    my ( $recce, $input ) = @_;
    my $input_length = length ${$input};
    for (
        my $pos = $recce->read($input);
        $pos < $input_length;
        $pos = $recce->resume()
      )
    {
      EVENT:
        for (
            my $event_ix = 0 ;
            my $event    = $recce->event($event_ix) ;
            $event_ix++
          )
        {
            my $name = $event->[0];
	    die qq{Unexpected event: name="$name"};
        }
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
}
