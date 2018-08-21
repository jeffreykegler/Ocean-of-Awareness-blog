#!/usr/bin/perl)

# Short example from the 2010 Language Report,
# p. 13.

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;
use English qw( -no_match_vars );

use Test::More tests => 2;
use Test::Differences;

use Marpa::R2 4.000;

require "haskell.pm";

my $short13 = <<'EOS';
f x = let a = 1; b = 2
          g y = exp2
      in exp1
EOS

my $short13_ast  = 
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
                'f'
              ],
              [
                'apat',
                [
                  'var',
                  'x'
                ]
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
                            'a'
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
                                    '1'
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
                            'b'
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
                                    '2'
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
                            'g'
                          ],
                          [
                            'apat',
                            [
                              'var',
                              'y'
                            ]
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
                                      'exp2'
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
                                'exp1'
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

my $short13_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($short13_ast) );

local $main::DEBUG = 0;

doTest( \$short13, $short13_expected );
$main::DEBUG = 0;

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

    # say "===\n", Data::Dumper::Dumper(
    # MarpaX::R2::Haskell::pruneNodes($valueRef) ), "===\n";

        $value = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($$valueRef) );
    }
    Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
}
