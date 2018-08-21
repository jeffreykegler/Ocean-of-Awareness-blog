#!/usr/bin/perl)

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;
use English qw( -no_match_vars );

use Test::More tests => 4;
use Test::Differences;

use Marpa::R2 4.000;

require "haskell.pm";

my $note1_implicit = <<'EOS';
main =
 let x = e; y = x in e'
EOS

my $note1_explicit = <<'EOS';
main =
 let { x = e; y = x } in e'
EOS

my $note1_implicit_ast =
  [
    'module',
    [
      'body',
      [
        'topdecls',
        [
          'topdecl',
          [
            'decl',
            [
              'funlhs',
              [
                'var',
                'main'
              ]
            ],
            [
              'rhs',
              '=',
              [
                'exp',
                [
                  'infixexp',
                  [
                    'lexp',
                    'let',
                    [
                      'decls',
                      [
                        'decl',
                        [
                          'funlhs',
                          [
                            'var',
                            'x'
                          ]
                        ],
                        [
                          'rhs',
                          '=',
                          [
                            'exp',
                            [
                              'infixexp',
                              [
                                'lexp',
                                [
                                  'fexp',
                                  [
                                    'aexp',
                                    [
                                      'qvar',
                                      'e'
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ],
                      [
                        'decl',
                        [
                          'funlhs',
                          [
                            'var',
                            'y'
                          ]
                        ],
                        [
                          'rhs',
                          '=',
                          [
                            'exp',
                            [
                              'infixexp',
                              [
                                'lexp',
                                [
                                  'fexp',
                                  [
                                    'aexp',
                                    [
                                      'qvar',
                                      'x'
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ],
                    'in',
                    [
                      'exp',
                      [
                        'infixexp',
                        [
                          'lexp',
                          [
                            'fexp',
                            [
                              'aexp',
                              [
                                'qvar',
                                'e\''
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
  ;

my $note1_implicit_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($note1_implicit_ast) );

local $main::DEBUG = 1;

doTest( \$note1_implicit, $note1_implicit_expected );
$main::DEBUG = 0;
doTest( \$note1_explicit, $note1_implicit_expected );

sub doTest {
    my ($inputRef, $expected_value ) = @_;
    my ($result, $valueRef) = MarpaX::R2::Haskell::parse($inputRef);
    if ( $result ne 'OK' ) {
        Test::More::fail(qq{Result was "$result", not OK});
        Test::More::fail(qq{No value test, because result was not OK});
        return
    }
    Test::More::pass(qq{Result is OK});
    my $value = '[fail]';
    if ($valueRef) {

    say "===\n", Data::Dumper::Dumper(
    MarpaX::R2::Haskell::pruneNodes($valueRef) ), "===\n";

        $value = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($$valueRef) );
    }
    Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
}
