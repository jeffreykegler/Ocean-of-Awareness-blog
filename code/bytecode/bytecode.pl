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
# statement ::= var '=' boolean
statement ::= if_statement
statement ::= label
statement ::= bytecodes
if_statement ::= 'if' var 'then' statements 'end'
if_statement ::= 'if' var 'then' statements 'else' statements 'end'
:discard ~ whitespace
whitespace ~ [\s]+
# boolean ~ 'true'
# boolean ~ 'false'
var ~ name
name ~ first_char later_chars
first_char ~ [_a-zA-Z]
later_chars  ~ [_a-zA-Z0-9]+
:lexeme ~ bytecodes priority => -1 pause => before event => 'before bytecodes'
bytecodes ~ [\S] # dummy -- procedural logic reads bytecodes
label ~ [^\d\D] # dummy -- procedural logic reads labels
END_OF_DSL

# TODO: add to grammar
# cond1 = true
# cond2 = false

my $test = <<'EOS';
if cond1 then
    LOAD 42
    LOAD 1792
    BUILD_LIST 2
if cond2 then
    LOAD 1
    LOAD 2
    BUILD_LIST 2
    BYTECODE_88:
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
    FINISH:
end
EOS

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

{
    my $expected_result = '';
    my $expected_value = '';
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar,
       trace_terminals => 99,
    } );
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
	    if ($name eq "before bytecodes") {
	       parse_bytecodes($recce, $input);
	       next EVENT;
	    }
	    die qq{Unexpected event: name="$name"};
        }
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
}

sub parse_bytecodes {
    my ( $recce, $input ) = @_;
    my $input_length = length ${$input};
    my $pos          = $recce->pos;
    my $last_eol     = rindex( ${$input}, "\n", $pos - 1 );
    my $line_start   = $last_eol + 1;
    my $line_prefix  = substr( ${$input}, $line_start, $pos - $line_start );
    my $line_end     = index( ${$input}, "\n", $pos );
    $line_end = $input_length if $line_end < 0;
    my $line_body = substr( ${$input}, $pos, $line_end - $pos );

    say STDERR "=== LINE BODY: ", $line_body;

    my $line = $line_prefix . $line_body;

    if ( $line_prefix =~ /[\S]/ ) {
        die
"bytecode must not have anything but whitespace before it on the same line\n",
          "Problem line was:\n",
          $line;
    }

    # Is the line a outer-layer label?
    if ( my ($label) = ( $line =~ m/ ^ ( [_A-Z] \w* [:] ) /xi ) ) {
	$recce->alternative('label', $label, length $label);
	say STDERR "outer label: ", $label;
    }

    my $bytecodes = '';

    LINE: while ($line_end < $input_length) {

      PROCESS_LINE: {
            last PROCESS_LINE if $line =~ /^ \s* $/x;

            # Is the line a outer-layer label?
            if ( my ($label) = ( $line =~ m/ ^ ( [_A-Z] \w* [:] ) /xi ) ) {
		$recce->alternative('bytecodes', $bytecodes, length $bytecodes);
                say STDERR "outer label: ", $label;
                last PROCESS_LINE;
            }
            if ( $line =~ /^ \s* [_A-Z] \w* [:] \s* $/xi ) {
                say STDERR "blockcode LABEL line: ", $line;
                last PROCESS_LINE;
            }
            if ( $line =~ /^ \s* LOAD \s \d+ \s* $/xi ) {
                say STDERR "blockcode LOAD line: ", $line;
                last PROCESS_LINE;
            }
            if ( $line =~ /^ \s* BUILD_LIST \s \d+ \s* $/xi ) {
                say STDERR "blockcode BUILD_LIST line: ", $line;
                last PROCESS_LINE;
            }
	    # if it is not a bytecode line, finish up
	    last LINE;
        }

	$bytecodes = $bytecodes . $line;
	$line_start     = $line_end+1;
	$line_end     = index( ${$input}, "\n", $line_start );
	$line_end = $input_length if $line_end < 0;

	$line = substr( ${$input}, $line_start, $line_end - $line_start );

    }

    $recce->earleme_complete();

}
