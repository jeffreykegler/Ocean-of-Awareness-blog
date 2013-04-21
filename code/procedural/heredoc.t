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
use autodie;
use Test::More tests => 1;

use Marpa::R2 2.052000;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
END_OF_USAGE_MESSAGE
} ## end sub usage

my $getopt_result = Getopt::Long::GetOptions();
usage() if not $getopt_result;

my $p = Demo::Heredoc::Parser->new;

my $v = $p->parse(<<"INPUT");
say <<ENDA, <<ENDB, <<ENDC; say <<ENDD;
line 1
line 2
line 3
ENDA
line 4
line 5
ENDB
line 6
line 7
ENDC
line 8
line 9
ENDD
say <<ENDE;
ENDE

INPUT

my $expected = 
[
    [
        [
            'say', [
                "line 1\nline 2\nline 3\n",
                "line 4\nline 5\n",
                "line 6\nline 7\n",
            ],
        ],
    ],
    [
        [
            'say', [
                "line 8\nline 9\n",
            ],
        ],
    ],
    [
        [
            'say', [
                "",
            ],
        ],
    ]
];

is_deeply($v, $expected);

package Demo::Heredoc::Parser;

sub new {
    my $class = shift;

    my $grammar = Marpa::R2::Scanless::G->new({
        default_action => '::array',

        source => \<<'GRAMMAR',

:start        ::= statements

statements    ::= statement+

# Statement should handle their own semicolons

statement     ::= expressions semicolon action => ::first
                | newline

expressions   ::= expression+            separator => comma

expression    ::= heredoc                action => ::first
                | 'say' expressions

# The heredoc rule is different from how the source code actually looks The
# pause adverb allows to send only the parts the are useful

heredoc       ::= (<heredoc op>) <heredoc terminator>       action => ::first

# Pause at <heredoc terminator> and at newlines.
:lexeme         ~ <heredoc terminator>    pause => before
:lexeme         ~ newline    pause => before

<heredoc op>    ~ '<<'
semicolon      ~ ';'
comma           ~ ','
newline         ~ [\n]

# The syntax here is for the terminator itself.
# The actual value of the <heredoc terminator> lexeme will
# the heredoc, which will be provided by the external heredoc scanner.
<heredoc terminator>         ~ [\w]+

# Only discard horizontal whitespace. If "\n" is included the parser won't
# pause at the end of line.

:discard        ~ ws
ws              ~ [ \t]+

GRAMMAR
    });

    my $self = {
        grammar => $grammar,
    };

    return bless $self, $class;
}

sub parse {
    my ( $self, $input ) = @_;

    my $re = Marpa::R2::Scanless::R->new( { grammar => $self->{grammar} } );

    # Start the parse
    my $pos = $re->read( \$input );
    die "error" if $pos < 0;

    my $last_heredoc_end;

    # Loop while the parse has't moved past the end
    PARSE_SEGMENT: while ( $pos < length $input ) {

        my $lexeme = $re->pause_lexeme();
        my ( $start_of_pause_lexeme, $length_of_pause_lexeme ) =
            $re->pause_span();
        my $end_of_pause_lexeme = $start_of_pause_lexeme + $length_of_pause_lexeme;

        if ( $re->pause_lexeme() eq 'newline' ) {

            # Resume from the end of the last heredoc, if there
            # was one.  Otherwise just resume at the start of the
            # next line.
            $pos = $re->resume( $last_heredoc_end // $end_of_pause_lexeme );
            $last_heredoc_end = undef;
            next PARSE_SEGMENT;
        } ## end if ( $re->pause_lexeme() eq 'newline' )

        # If we are here, the pause lexeme was <heredoc terminator>

        # Find the <heredoc terminator>
        my $terminator = $re->literal($start_of_pause_lexeme, $length_of_pause_lexeme);

        my $heredoc_start = $last_heredoc_end
            // ( index( $input, "\n", $pos ) + 1 );

        # Find the heredoc body --
	# the literal text between the end of the last heredoc
	# and the heredoc terminator for this heredoc
        pos $input = $heredoc_start;
        my ($heredoc_body) = ( $input =~ m/\G(.*)^$terminator\n/gmsc );
        die "Heredoc terminator $terminator not found before end of input"
            if not defined $heredoc_body;

        # Pass the heredoc to the parser as the value of <heredoc terminator>
        $re->lexeme_read( 'heredoc terminator', $heredoc_start, length($heredoc_body),
            $heredoc_body ) // die $re->show_progress;

        # Save of the position of the end of the match
        # The next heredoc body starts there if there is one
        $last_heredoc_end = pos $input;

        # Resume parsing from the end of the <heredoc terminator> lexeme
        $pos = $re->resume($end_of_pause_lexeme);

    } ## end PARSE_SEGMENT: while ( $pos < length $input )

    my $v = $re->value;
    return $$v;
} ## end sub parse

