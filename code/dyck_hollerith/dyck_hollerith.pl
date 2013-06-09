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

sub arg1 { return $_[1]; }
sub arg4 { return $_[4]; }
sub all_args { shift; return \@_; }

my $dsl = <<'END_OF_DSL';
:start ::= sentence
sentence ::= element
string ::= ('S' count '(') text (')')
array ::= ('A' count '(') elements (')')
elements ::= element+
element ::= string | array
:lexeme ~ count pause => after
:lexeme ~ text pause => before
count ~ [\d]+
text ~ [\d\D] # one character of anything, just to trigger the pause
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new(
    {   
	action_object => 'My_Actions',
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

my $last_hollerith_count = 0;
INPUT: for (my $pos = $recce->read(\$input); $pos < length $input; $pos = $recce->resume($pos)) {
    my $lexeme = $recce->pause_lexeme();
    if ($lexeme eq 'count') {
        $last_hollerith_count = $recce->literal($recce->pause_span()) + 0;
	next INPUT;
    }
    # We paused before the lexeme text
    my $text_value = $recce->lexeme_read('text', $pos, $last_hollerith_count);
}

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

