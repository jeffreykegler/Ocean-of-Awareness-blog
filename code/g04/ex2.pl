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
use Data::Dumper;
use GetOpt::Long;

use Marpa::R2 2.047_012;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
    $PROGRAM_NAME --verbose
Runs a demo.
By default, prints the only the result AST evaluation.
With --verbose, dumps the AST.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $verbose_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'verbose!' => \$verbose_flag, );
usage() if not $getopt_result;

# Note Go4 ignores precedence
my $rules = <<'END_OF_GRAMMAR';
:default ::= action => ::array bless => ::lhs

:start ::= <boolean expression>
<boolean expression> ::=
       <variable> bless => variable
     | '1' bless => constant
     | '0' bless => constant
     | ('(') <boolean expression> (')') action => ::first bless => ::undef
    || ('not') <boolean expression> bless => not
    || <boolean expression> ('and') <boolean expression> bless => and
    || <boolean expression> ('or') <boolean expression> bless => or

<variable> ~ [[:alpha:]] <zero or more word characters>
<zero or more word characters> ~ [\w]*

:discard ~ whitespace
whitespace ~ [\s]+
END_OF_GRAMMAR

my $grammar = Marpa::R2::Scanless::G->new(
    {   bless_package => 'Boolean_Expression',
        source        => \$rules,
    }
);

sub bnf_to_ast {
    my ($bnf) = @_;
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    $recce->read( \$bnf );
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse for $bnf";
    }
    return ${$value_ref};
} ## end sub bnf_to_ast

my $context = Context->new();
$context->assign( x => 0 );
$context->assign( y => 1 );
$context->assign( z => 1 );
say $context->dump();

my $bnf = q{1 and x or y and not x};
my $ast1 = bnf_to_ast($bnf);
say qq{Boolean 1 is "$bnf"};
say "Value is ", $ast1->evaluate($context) ? 'true' : 'false';
say Data::Dumper::Dumper($ast1) if $verbose_flag;

$bnf = 'not z';
my $ast2 = bnf_to_ast($bnf);
say qq{Boolean 2 is "$bnf"};
say "Value is ", $ast2->evaluate($context) ? 'true' : 'false';
say Data::Dumper->Dump([$ast2], ['ast2']) if $verbose_flag;

my $ast3 = $ast1->replace( 'y', $ast2 );
say q{Boolean 3 is Boolean 1, with "y" replaced by Boolean 2};
say "Value is ", $ast3->evaluate($context) ? 'true' : 'false';
say Data::Dumper->Dump([$ast3], ['ast3']) if $verbose_flag;

exit 0;

package Context;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub assign {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value;
}

sub lookup {
    my ( $self, $name ) = @_;
    my $value = $self->{$name};
    die qq{Attempt to read undefined boolean variable named "$name"}
        if not defined $value;
    return $value;
} ## end sub lookup

sub dump {
    my ( $self ) = @_;
    return join q{ }, map { join q{=}, $_, $self->{$_} } keys %{$self};
}

package Boolean_Expression::constant;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($value) = @{$self};
    return $value;
}

sub copy {
    my ($self)  = @_;
    my ($value) = @{$self};
    return bless [$value], ref $self;
}

sub replace {
    my ($self) = @_;
    return $self->copy();
}

package Boolean_Expression::variable;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($name) = @{$self};
    return 1 if $name eq 'true';
    return 0
        if $name eq 'false';
    my $value = $context->lookup($name);
    return $value;
} ## end sub evaluate

sub copy {
    my ($self) = @_;
    my ($name) = @{$self};
    return bless [$name], ref $self;
}

sub replace {
    my ( $self, $name_to_replace, $expression ) = @_;
    my ($my_name) = @{$self};
    return $expression->copy() if $my_name eq $name_to_replace;
    return $self->copy();
} ## end sub replace

package Boolean_Expression::not;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($exp1) = @{$self};
    return !$exp1->evaluate($context);
}

sub copy {
    my ($self) = @_;
    return bless [ map { $_->copy() } @{$self} ], ref $self;
}

sub replace {
    my ( $self, $name, $expression ) = @_;
    return bless [ map { $_->replace( $name, $expression ) } @{$self} ],
        ref $self;
}

package Boolean_Expression::and;

sub evaluate {
    my ( $self, $context ) = @_;
    my ( $exp1, $exp2 )    = @{$self};
    return $exp1->evaluate($context) && $exp2->evaluate($context);
}

sub copy {
    my ($self) = @_;
    return bless [ map { $_->copy() } @{$self} ], ref $self;
}

sub replace {
    my ( $self, $name, $expression ) = @_;
    return bless [ map { $_->replace( $name, $expression ) } @{$self} ],
        ref $self;
}

package Boolean_Expression::or;

sub evaluate {
    my ( $self, $context ) = @_;
    my ( $exp1, $exp2 )    = @{$self};
    return $exp1->evaluate($context) || $exp2->evaluate($context);
}

sub copy {
    my ($self) = @_;
    return bless [ map { $_->copy() } @{$self} ], ref $self;
}

sub replace {
    my ( $self, $name, $expression ) = @_;
    return bless [ map { $_->replace( $name, $expression ) } @{$self} ],
        ref $self;
}

# vim: expandtab shiftwidth=4:
