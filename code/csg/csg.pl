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
S ::= prefix ABC trailer
ABC ::= ABs Cs
ABs ::= A ABs B | A B
prefix ::= A*
trailer ::= C_extra*
A ~ 'a'
B ~ 'b'
:lexeme ~ Cs pause => before event => 'before C'
Cs ~ 'c' # dummy -- procedural logic reads <Cs>
C_extra ~ 'c'
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
	  if ($eval_error =~ m/No lexeme found/) {
	     $result = "Too few A's or no B's";
	     last PARSE_EVAL_ERROR;
	  }
	  if ($eval_error =~ m/Too few C's/) {
	     $result = "Too few C's";
	     last PARSE_EVAL_ERROR;
	  }
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
            if ( $name eq 'before C' ) {
                my ( $start, $length ) = $recce->last_completed_span('ABs');
                my $c_length = ($length) / 2;
                my $c_seq = ( 'c' x $c_length );
                if ( substr( ${$input}, $pos, $c_length ) eq $c_seq ) {
                    $recce->lexeme_read( 'Cs', $pos, $c_length, $c_seq );
		    next EVENT;
                }
		die qq{Too few C's};
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
