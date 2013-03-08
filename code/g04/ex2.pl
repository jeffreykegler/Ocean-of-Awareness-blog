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
use GetOpt::Long;

use Marpa::R2 2.047_012;

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME --demo
    $PROGRAM_NAME < file
With --stdin arg, reads expression from standard input.
By default, runs a demo.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $demo_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'demo!' => \$demo_flag, );
usage() if not $getopt_result;

my $input;
GET_INPUT: {
    if ($demo_flag) {

        # eliminate Marpa does precedence
        $input = q{1 and x or y and not x};
    }
    if ( not $demo_flag ) {
        $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
    }
} ## end GET_INPUT:

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
        source         => \$rules,
    }
);


my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar, } );
$recce->read(\$input);
my $value_ref = $recce->value();
if ( not defined $value_ref ) {
    die "No parse";
}

my $context = Context->new();
$context->assign( x => 0 );
$context->assign( y => 1 );
say ${$value_ref}->evaluate($context);

# say Data::Dumper::Dumper($value_ref);

package Context;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub assign {
    my ($self, $name, $value) = @_;
    $self->{$name} = $value;
}

sub lookup {
    my ($self, $name) = @_;
    my $value = $self->{$name};
    die qq{Attempt to read undefined boolean variable named "$name"} if not defined $value;
    return $value;
}

package Boolean_Expression::constant;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($value) = @{$self};
    return $value;
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

package Boolean_Expression::not;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($exp1) = @{$self};
    return !$exp1->evaluate($context);
} ## end sub evaluate

package Boolean_Expression::and;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($exp1, $exp2) = @{$self};
    return $exp1->evaluate($context) && $exp2->evaluate($context);
} ## end sub evaluate

package Boolean_Expression::or;

sub evaluate {
    my ( $self, $context ) = @_;
    my ($exp1, $exp2) = @{$self};
    return $exp1->evaluate($context) || $exp2->evaluate($context);
} ## end sub evaluate

# vim: expandtab shiftwidth=4:
