#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 6;

use Marpa::R2 2.090;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1
S ::= prefix ABC trailer
ABC ::= ABs Cs
ABs ::= A ABs B | A B
prefix ::= A*
trailer ::= C_extra*
:lexeme ~ Cs pause => before event => 'before C'
A ~ 'a'
B ~ 'b'
Cs ~ 'c'
C_extra ~ 'c'
END_OF_DSL

my @ex = ('abc',
 'aabbcc',
 'aaabccc',
 'aabbcccc',
 'aabbccc',
 'aaaaabbccc',
);

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

TEST: for my $ix (0 .. $#ex)
{
    my $input = \($ex[$ix]);
    my $i = $ix + 1;
    say "** Test #$i: ", ${$input};
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $value_ref;
    my $eval_ok = eval { $value_ref = doit( $recce, $input ); 1; };
    if ( !$eval_ok ) {
        Test::More::fail("Example $i failed");
        Test::More::diag($EVAL_ERROR);
	next TEST;
    }
    say flatten($value_ref);
    Test::More::pass( "Example $i OK" );
} ## end TEST:

sub flatten {
    my ($tree) = @_;
    if ( ref $tree eq 'REF' ) { return flatten( ${$tree} ); }
    if ( ref $tree eq 'ARRAY' ) {
        return join " ", map { flatten($_) } @{$tree};
    }
    return $tree;
} ## end sub flatten

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
                # say STDERR "pos = $pos";
                # say STDERR "start = $start; length = $length";
                # say STDERR "substr = " . substr( ${$input}, $pos, $c_length );
                my $c_seq = ( 'c' x $c_length );
                if ( substr( ${$input}, $pos, $c_length ) eq $c_seq ) {
                    # say STDERR "Event $name NYI Match!";
                    $recce->lexeme_read( 'Cs', $pos, $c_length, $c_seq );
                    next EVENT;
                }
                die "Event $name NYI no match";
            }
        }
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
} ## end sub doit
