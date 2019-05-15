use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Getopt::Long;

use Marpa::R2 8.000000;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
    $PROGRAM_NAME --stdin < file
With --stdin arg, reads expression from standard input.
By default, runs a test.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $stdin_flag = 1;
my $interOffset;
my $preOffset;
my $getopt_result = Getopt::Long::GetOptions(
    'stdin!' => \$stdin_flag,
    'inter:i' => \$interOffset,
    'pre:i' => \$preOffset,
);

usage() if not $getopt_result;
die "interOffset required" if not defined $interOffset;
# convert to 1-based
$interOffset -= 1;
$preOffset -= 1 if defined $preOffset;

my $input;
if ($stdin_flag) {
    $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
}

my @lineToPos = ( -1, 0 );
{
    my $lastPos = 0;
  LINE: while (1) {
        my $newPos = index $input, "\n", $lastPos;

        # say $newPos;
        last LINE if $newPos < 0;
        $lastPos = $newPos + 1;
        push @lineToPos, $lastPos;
    }
}
# say STDERR join " ", __FILE__, __LINE__, Data::Dumper::Dumper(\@lineToPos);

sub FakeInstance::literalLine {
    my ( $instance, $lineNum ) = @_;
    my $lineToPos     = $instance->{lineToPos};
    my $startPos = $lineToPos->[$lineNum];
    my $line =
      $instance->literal( $startPos,
        ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
    return $line;
}

sub FakeInstance::literal {
    my ( $instance, $start, $length ) = @_;
    my $pSource = $instance->{pHoonSource};
    return '' if $start >= length ${$pSource};
    return substr ${$pSource}, $start, $length;
}

my $gapCommentDSL = <<'END_OF_DSL';
:start ::= gapComments
gapComments ::= OptExceptions Body
gapComments ::= OptExceptions
Body ::= InterPart PrePart
Body ::= InterPart
Body ::= PrePart
InterPart ::= InterComponent
InterPart ::= InterruptedInterComponents
InterPart ::= InterruptedInterComponents InterComponent

InterruptedInterComponents ::= InterruptedInterComponent+
InterruptedInterComponent ::= InterComponent Exceptions
InterComponent ::= Staircases
InterComponent ::= Staircases InterComments
InterComponent ::= InterComments

InterComments ::= InterComment+

Staircases ::= Staircase+
Staircase ::= UpperRisers Tread LowerRisers
UpperRisers ::= UpperRiser+
LowerRisers ::= LowerRiser+

PrePart ::= ProperPreComponent OptPreComponents
ProperPreComponent ::= PreComment
OptPreComponents ::= PreComponent*
PreComponent ::= ProperPreComponent
PreComponent ::= Exception

OptExceptions ::= Exception*
Exceptions ::= Exception+
Exception ::= MetaComment
Exception ::= BadComment
Exception ::= BlankLine

unicorn ~ [^\d\D]
BadComment ~ unicorn
BlankLine ~ unicorn
InterComment ~ unicorn
LowerRiser ~ unicorn
MetaComment ~ unicorn
PreComment ~ unicorn
Tread ~ unicorn
UpperRiser ~ unicorn

END_OF_DSL

my $gapGrammar = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Actions',
        default_action => 'do_arg0',
        source         => \$gapCommentDSL,
    }
);

my $recce = Marpa::R2::Scanless::R->new( { grammar => $gapGrammar } );

my $self = bless { grammar => $gapGrammar }, 'My_Actions';
$self->{recce}        = $recce;
$self->{symbol_table} = {};
local $My_Actions::SELF = $self;

if ( not defined eval { $recce->read( \$input, 0, 0 ); 1 } ) {

    # Add last expression found, and rethrow
    my $eval_error = $EVAL_ERROR;
    chomp $eval_error;
    die $eval_error, "\n";
} ## end if ( not defined eval { $recce->read($p_string); 1 })

my $fakedInstance = bless {
       pHoonSource => \$input,
       lineToPos => \@lineToPos,
}, 'FakeInstance';

my $fakedPolicy = bless {
    lint => $fakedInstance,
    gapGrammar => $gapGrammar,
}, 'FakePolicy';

my $mistakes = checkGapComments($fakedPolicy, 1, ($#lineToPos-1), $interOffset, $preOffset);
say Data::Dumper::Dumper($mistakes);

sub checkGapComments {
    my ( $policy, $firstLine, $lastLine, $interOffset, $preOffset ) = @_;
    # say STDERR join " ", __FILE__, __LINE__,  $policy, $firstLine, $lastLine, $interOffset, $preOffset;
    return if $lastLine < $firstLine;
    my $instance = $policy->{lint};
    my $pSource = $instance->{pHoonSource};
    my $lineToPos = $instance->{lineToPos};
    if (defined $preOffset and $preOffset == $interOffset) {
      $preOffset = undef; # Do not allow pre-offset to be equal to inter-offset
    }
    my @mistakes = ();

    my $grammar = $policy->{gapGrammar};
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $startPos = $lineToPos->[$firstLine];
    my $input = $instance->literal( $startPos,
        ( $lineToPos->[ $lastLine + 1 ] - $startPos ) );

        # say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine", qq{"$input"};

    if ( not defined eval { $recce->read( $pSource, $startPos, 0 ); 1 } ) {

    my $eval_error = $EVAL_ERROR;
    chomp $eval_error;
    say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine", qq{"$input"};
    die $eval_error, "\n";
    }

    my $lineNum = 0;
  LINE:
    for ( my $lineNum = $firstLine ; $lineNum <= $lastLine ; $lineNum++ ) {
        my $line = $instance->literalLine($lineNum);

        # say STDERR join ' ', __FILE__, __LINE__, $lineNum, qq{"$line"};

      FIND_ALTERNATIVES: {
            my $expected = $recce->terminals_expected();

            # say Data::Dumper::Dumper($expected);
            my $tier1_ok;
            my @tier2 = ();
        my @failedOffsets = ();
          TIER1: for my $terminal ( @{$expected} ) {

                # say STDERR join ' ', __FILE__, __LINE__, $terminal;
                if ( $terminal eq 'InterComment' ) {
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, qq{"$line"};
                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
            next TIER1;
                    }
            push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'PreComment' ) {
                    next TIER1 if not defined $preOffset;
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $preOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
            next TIER1;
                    }
            push @failedOffsets, $preOffset;
            next TIER1;
                }
                if ( $terminal eq 'Tread' ) {
                    $line =~ m/^ [ ]* ([:][:][:][:][ \n]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
            next TIER1;
                    }
            push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'UpperRiser' ) {
                    $line =~ m/^ [ ]* ([:][:]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
            next TIER1;
                    }
            push @failedOffsets, $interOffset;
                    next TIER1;
                }
                if ( $terminal eq 'LowerRiser' ) {
                    $line =~ m/^ [ ]* ([:][:]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    # say STDERR join ' ', __FILE__, __LINE__, $commentOffset;
                    if ( $commentOffset == $interOffset + 2 ) {

                        # say STDERR join ' ', __FILE__, __LINE__;
                        $recce->lexeme_alternative( $terminal, $line );
                        $tier1_ok = 1;
            next TIER1;
                    }
            push @failedOffsets, $interOffset;
                    next TIER1;
                }
                push @tier2, $terminal;
            }

            # If we found a tier 1 lexeme, do not look for the "backup"
            # lexemes on the other tiers
            last FIND_ALTERNATIVES if $tier1_ok;

            my @tier3 = ();
          TIER2: for my $terminal (@tier2) {
                if ( $terminal eq 'MetaComment' ) {
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    next TIER2 if not defined $commentOffset;
                    if ( $commentOffset == 0 ) {
                        $recce->lexeme_alternative( $terminal, $line );

                  # anything in this tier terminates the finding of alternatives
                        last FIND_ALTERNATIVES;
                    }
            push @failedOffsets, $interOffset;
                }
                push @tier3, $terminal;
            }

          TIER3: for my $terminal (@tier3) {
                if ( $terminal eq 'BlankLine' ) {
                    # say STDERR join ' ', __FILE__, __LINE__, $lineNum, qq{"$line"};
                    if ( $line =~ m/\A [\n ]* \z/xms ) {
                        $recce->lexeme_alternative( $terminal, $line );

                  # anything in this tier terminates the finding of alternatives
                        push @mistakes, [ 'vgap-blank-line', $lineNum ];
                        last FIND_ALTERNATIVES;
                    }
                }
                if ( $terminal eq 'BadComment' ) {
                    if ( $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x ) {
                        $recce->lexeme_alternative( $terminal, $line );
                        my $commentOffset = $LAST_MATCH_START[1];

            my $closestHiOffset;
            my $closestLoOffset;
            # say STDERR Data::Dumper::Dumper(\@failedOffsets);
            for my $failedOffset (@failedOffsets) {
                if ($failedOffset > $commentOffset) {
                    if (not defined $closestHiOffset or $failedOffset < $closestHiOffset) {
                    $closestHiOffset = $failedOffset;
                }
                }
                if ($failedOffset < $commentOffset) {
                    if (not defined $closestLoOffset or $failedOffset > $closestLoOffset) {
                    $closestLoOffset = $failedOffset;
                }
                }
            }
            my $closestOffset = ($closestLoOffset // $closestHiOffset);
            # say STDERR join ' ', __LINE__, 'vgap-bad-comment', $lineNum, $commentOffset, $closestOffset ;
                        push @mistakes,
                          [ 'vgap-bad-comment', $lineNum, $commentOffset, $closestOffset ];

                  # anything in this tier terminates the finding of alternatives
                        last FIND_ALTERNATIVES;
                    }
                }
            }

        }
        my $startPos = $lineToPos->[$lineNum];

        # say STDERR join ' ', __FILE__, __LINE__;
        my $eval_ok = eval {
            $recce->lexeme_complete( $startPos,
                ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
            1;
        };
        if ( not $eval_ok ) {

            my $eval_error = $EVAL_ERROR;
            chomp $eval_error;
            # say STDERR join ' ', __FILE__, __LINE__, "$firstLine-$lastLine",
              # qq{"$input"};
            die $eval_error, "\n";
        }
    }
    my $metric = $recce->ambiguity_metric();
    if ($metric != 1) {
       my $issue = $metric ? "ambiguous" : "no parse";
    say STDERR $recce->show_progress(0, -1);
    say STDERR $input;
    # say STDERR join " ", __FILE__, __LINE__,  $policy, $firstLine, $lastLine, $interOffset, $preOffset;
    die "Bad gap combinator parse: $issue\n";
    }
    return \@mistakes;
}


# my $value_ref = $recce->value();
# if ( not defined $value_ref ) {
# die $self->show_last_expression(), "\n",
# "No parse was found, after reading the entire input\n";
# }
# return ${$value_ref}, $self->{symbol_table};

package My_Actions;
our $SELF;
sub new { return $SELF }

sub do_negate {
    return -$_[2];
}

sub do_arg0 { return $_[1]; }
sub do_arg1 { return $_[2]; }
sub do_arg2 { return $_[3]; }

# vim: expandtab shiftwidth=4:
