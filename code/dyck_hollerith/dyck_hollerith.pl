use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;
use Marpa::R2;

# A Marpa::R2 parser for the Dyck-Hollerith language

my $repeat;
if (@ARGV) {
    $repeat = $ARGV[0];
    die "Argument not a number" if not Scalar::Util::looks_like_number($repeat);
}

my $dsl = <<'END_OF_DSL';
:start ::= sentence
sentence ::= element
string ::= ( 'S' <string length> '(' ) text ( ')' )
array ::= ('A') <array count> ('(') elements ( ')' )
elements ::= element+
element ::= string | array
:lexeme ~ <array count> pause => after
:lexeme ~ <string length> pause => after
:lexeme ~ text pause => before
<array count> ~ [\d]+
<string length> ~ [\d]+
text ~ [\d\D] # one character of anything, just to trigger the pause
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new(
    {   
	action_object => 'My_Actions',
	default_action => '::array',
        source => \$dsl
    }
);

my $recce = Marpa::R2::Scanless::R->new({ grammar => $grammar });

my $input;
if ($repeat) {
    $input = "A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')';
} else {
    $input = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

my $last_string_length;
my $input_length = length $input;
INPUT:
for (
    my $pos = $recce->read( \$input );
    $pos < $input_length;
    $pos = $recce->resume($pos)
    )
{
    my $lexeme = $recce->pause_lexeme();
    if (not defined $lexeme) {
      my $event_ix = 0;
      while (my $event = $recce->event($event_ix++)) { say Data::Dumper::Dumper($event); }
	# die qq{Parse exhausted in front of this string: "}, substr($input, $pos), '"';
      die 'Unexplained pause in reading';
    }
    my ( $start, $lexeme_length ) = $recce->pause_span();
    if ( $lexeme eq 'string length' ) {
        $last_string_length = $recce->literal( $start, $lexeme_length ) + 0;
        $pos = $start + $lexeme_length;
        next INPUT;
    }
    if ( $lexeme eq 'array count' ) {
        my $array_count = $recce->literal( $start, $lexeme_length ) + 0;
        $recce->lexeme_read( 'array count', $start, $lexeme_length,
            $array_count );
        $pos = $start + $lexeme_length;
        next INPUT;
    } ## end if ( $lexeme eq 'array count' )
    if ( $lexeme eq 'text' ) {
        my $text_length = $last_string_length;
        $recce->lexeme_read( 'text', $start, $text_length );
        $pos = $start + $text_length;
        next INPUT;
    } ## end if ( $lexeme eq 'text' )
    die "Unexpected lexeme: $lexeme";
} ## end INPUT: for ( my $pos = $recce->read( \$input ); $pos < length...)

my $result = $recce->value();
die "No parse" if not defined $result;
my $received = Dumper(${$result});

my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
if ($received eq $expected )
{
    say "Output matches";
} else {
    say "Output differs: $received";
}

package My_Actions;

sub new {};

