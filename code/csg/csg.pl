#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 4;

use Marpa::R2 2.090;

my $dsl = <<'END_OF_DSL';
:default ::= action => [name,values]
lexeme default = latm => 1
S ::= AB C
AB ::= 'a' 'b'
AB ::= 'a' AB 'b'
C ::= [^\d\D]
event '^C' = predicted <C>
END_OF_DSL

my @ex = ('abc',
 'aabbcc',
 'aabbc',
 'aabbccc',
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
    my $input_length = ${$input};
    my $length_read  = $recce->read($input);
    EVENT:
    for (
        my $event_ix = 0;
        my $event    = $recce->event($event_ix);
        $event_ix++
        )
    {

        my $event = $recce->event($event_ix);
        my $name  = shift @{$event};
        if ( $name eq '^C' ) {
            die"Event $name NYI";
            next EVENT;
        } ## end if ( $name eq 'expecting text' )
        die "Unexpected event: ", join q{ }, @{$event};
    }

    if ( $length_read != length $input_length ) {
        die "read() ended prematurely\n",
            "  input length = $input_length\n",
            "  length read = $length_read\n";
    } ## end if ( $length_read != length $input_length )
    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
} ## end sub doit
