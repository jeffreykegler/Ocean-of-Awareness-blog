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
S ::= ABC
S ::= D
S ::= ABC D
S ::= D ABC

ABC ~ 'abc'
D ~ 'd'
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_DSL

my @ex = ('abc d',
 'd abc',
 'd abc d',
 'd',
 'abc',
 'abc d d'
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
    if ( $length_read != length $input_length ) {
        die "read() ended prematurely\n",
            "  input length = $input_length\n",
            "  length read = $length_read\n",
            "  the cause may be an unexpected event";
    } ## end if ( $length_read != length $input_length )
    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
} ## end sub doit
