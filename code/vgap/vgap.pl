use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Getopt::Long;
use Test::More;

use Marpa::R2 8.000000;

package FakeInstance;
our $literalLine;
our $literal;

package main;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
    $PROGRAM_NAME --stdin < file
With --stdin arg, reads expression from standard input.
By default, runs a test.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $stdinFlag = 0;
my $argInterOffset;
my $argPreOffset;
my $getopt_result = Getopt::Long::GetOptions(
    'stdin!'  => \$stdinFlag,
    'inter:i' => \$argInterOffset,
    'pre:i'   => \$argPreOffset,
);

usage() if not $getopt_result;

# Test format is input, output, inter-comment, pre-comment
# indents are 0-based
my @default_tests = (
    [
        <<'EOS'
    :: pre-comment 1
EOS
        , [], 4
    ],
    [
        <<'EOS'
  ::
      :: pre-comment 1
EOS
        , [], 2, 6
    ],
    [
        <<'EOS'
  ::
      :: pre-comment 2
EOS
        , [], 2, 6
    ],
    [
        <<'EOS'
  ::
      :: pre-comment 3
EOS
        , [], 2, 6
    ],
    [
        <<'EOS'
::::
::    :: pre-comment 3
::    [4 qax]
  ::
      :: pre-comment 4
EOS
        , [], 2, 6
    ],
    [
        <<'EOS'
::                                                      ::
::::  3e: AES encryption  (XX removed)                  ::
  ::                                                    ::
  ::
::                                                      ::
::::  3f: scrambling                                    ::
  ::                                                    ::
  ::    ob                                              ::
  ::
EOS
        , [], 0
    ],
    [
        <<'EOS'
::
::
 :: bad comment
::
  :: worse comment
::
  :: worser comment
:: next line is blank

::::  meta-comment
::                                                      ::
::::  tread
  ::
  ::
EOS
        ,
        [
            [ 'vgap-bad-comment', 3, '1', 0 ],
            [ 'vgap-bad-comment', 5, '2', 0 ],
            [ 'vgap-bad-comment', 7, '2', 0 ],
            [ 'vgap-blank-line',  9 ]
        ],
        0
    ],
);

my @tests = ();

my $input;
if ($stdinFlag) {
    $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
    die "interOffset required" if not defined $argInterOffset;

    # convert to 1-based
    $argInterOffset -= 1;
    $argPreOffset -= 1 if defined $argPreOffset;

    push @tests, [ $input, [], $argInterOffset, $argPreOffset ];
}

if ( not @tests ) {
    @tests = @default_tests;
    Test::More::plan tests => 7;
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

package main;

my $gapGrammar = Marpa::R2::Scanless::G->new( { source => \$gapCommentDSL } );

sub checkGapComments {
    my ( $policy, $firstLine, $lastLine, $interOffset, $preOffset ) = @_;

    return if $lastLine < $firstLine;
    my $instance  = $policy->{lint};
    my $pSource   = $instance->{pHoonSource};
    my $lineToPos = $instance->{lineToPos};
    if ( defined $preOffset and $preOffset == $interOffset ) {
        $preOffset =
          undef;    # Do not allow pre-offset to be equal to inter-offset
    }
    my @mistakes = ();

    my $grammar  = $policy->{gapGrammar};
    my $recce    = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
    my $startPos = $lineToPos->[$firstLine];
    my $input    = $instance->literal( $startPos,
        ( $lineToPos->[ $lastLine + 1 ] - $startPos ) );

    if ( not defined eval { $recce->read( $pSource, $startPos, 0 ); 1 } ) {

        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $eval_error, "\n";
    }

    my $lineNum = 0;
  LINE:
    for ( my $lineNum = $firstLine ; $lineNum <= $lastLine ; $lineNum++ ) {
        my $line = $instance->literalLine($lineNum);

      FIND_ALTERNATIVES: {
            my $expected = $recce->terminals_expected();

            # say Data::Dumper::Dumper($expected);
            my $tier1_ok;
            my @tier2         = ();
            my @failedOffsets = ();
          TIER1: for my $terminal ( @{$expected} ) {

                if ( $terminal eq 'InterComment' ) {
                    $line =~ m/^ [ ]* ([+][|]|[:][:]|[:][<]|[:][>]) /x;
                    my $commentOffset = $LAST_MATCH_START[1];
                    $commentOffset //= -1;

                    if ( $commentOffset == $interOffset ) {

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

                    if ( $commentOffset == $preOffset ) {

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

                    if ( $commentOffset == $interOffset ) {

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

                    if ( $commentOffset == $interOffset ) {

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

                    if ( $commentOffset == $interOffset + 2 ) {

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

                        for my $failedOffset (@failedOffsets) {
                            if ( $failedOffset > $commentOffset ) {
                                if ( not defined $closestHiOffset
                                    or $failedOffset < $closestHiOffset )
                                {
                                    $closestHiOffset = $failedOffset;
                                }
                            }
                            if ( $failedOffset < $commentOffset ) {
                                if ( not defined $closestLoOffset
                                    or $failedOffset > $closestLoOffset )
                                {
                                    $closestLoOffset = $failedOffset;
                                }
                            }
                        }
                        my $closestOffset =
                          ( $closestLoOffset // $closestHiOffset );

                        push @mistakes,
                          [
                            'vgap-bad-comment', $lineNum,
                            $commentOffset,     $closestOffset
                          ];

                  # anything in this tier terminates the finding of alternatives
                        last FIND_ALTERNATIVES;
                    }
                }
            }

        }
        my $startPos = $lineToPos->[$lineNum];

        my $eval_ok = eval {
            $recce->lexeme_complete( $startPos,
                ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
            1;
        };
        if ( not $eval_ok ) {

            my $eval_error = $EVAL_ERROR;
            chomp $eval_error;

            die $eval_error, "\n";
        }
    }
    my $metric = $recce->ambiguity_metric();
    if ( $metric != 1 ) {
        my $issue = $metric ? "ambiguous" : "no parse";
        say STDERR $recce->show_progress( 0, -1 );
        say STDERR $input;

        die "Bad gap combinator parse: $issue\n";
    }
    return \@mistakes;
}

TEST: for my $test (@tests) {
    my ( $input, $output, $interOffset, $preOffset ) = @{$test};
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

    my $fakedInstance = bless {
        pHoonSource => \$input,
        lineToPos   => \@lineToPos,
      },
      'FakeInstance';

    my $fakedPolicy = bless {
        lint       => $fakedInstance,
        gapGrammar => $gapGrammar,
      },
      'FakePolicy';

    *FakeInstance::literalLine = sub {
        my ( $instance, $lineNum ) = @_;
        my $lineToPos = $instance->{lineToPos};
        my $startPos  = $lineToPos->[$lineNum];
        my $line =
          $instance->literal( $startPos,
            ( $lineToPos->[ $lineNum + 1 ] - $startPos ) );
        return $line;
    };

    *FakeInstance::literal = sub {
        my ( $instance, $start, $length ) = @_;
        my $pSource = $instance->{pHoonSource};
        return '' if $start >= length ${$pSource};
        return substr ${$pSource}, $start, $length;
    };

    my $recce = Marpa::R2::Scanless::R->new( { grammar => $gapGrammar } );

    if ( not defined eval { $recce->read( \$input, 0, 0 ); 1 } ) {

        # Add last expression found, and rethrow
        my $eval_error = $EVAL_ERROR;
        chomp $eval_error;
        die $eval_error, "\n";
    } ## end if ( not defined eval { $recce->read($p_string); 1 })

    my $mistakes = checkGapComments( $fakedPolicy, 1, ( $#lineToPos - 1 ),
        $interOffset, $preOffset );

    if ($stdinFlag) {
        plan skip_all => 'Tests skipped in stdin mode';
        last TEST;
    }

    my $actual   = Data::Dumper::Dumper($mistakes);
    my $expected = Data::Dumper::Dumper($output);
    Test::More::is( $actual, $expected );

}

# vim: expandtab shiftwidth=4:
