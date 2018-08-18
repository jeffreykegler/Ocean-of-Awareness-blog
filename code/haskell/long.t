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

my $long_implicit = <<'EOS';
module AStack( Stack, push, pop, top, size ) where  
data Stack a = Empty  
             | MkStack a (Stack a)  
 
push :: a -> Stack a -> Stack a  
push x s = MkStack x s  
 
size :: Stack a -> Int  
size s = length (stkToLst s)  where  
           stkToLst  Empty         = []  
           stkToLst (MkStack x s)  = x:xs where xs = stkToLst s  
 
pop :: Stack a -> (a, Stack a)  
pop (MkStack x s)  
  = (x, case s of r -> i r where i x = x) -- (pop Empty) is an error  
 
top :: Stack a -> a  
top (MkStack x s) = x                     -- (top Empty) is an error
EOS

my $long_explicit = <<'EOS';
module AStack( Stack, push, pop, top, size ) where
{data Stack a = Empty
             | MkStack a (Stack a)

;push :: a -> Stack a -> Stack a
;push x s = MkStack x s

;size :: Stack a -> Int
;size s = length (stkToLst s) where 
           {stkToLst Empty = []
           ;stkToLst (MkStack x s) = x:xs where {xs = stkToLst s

}};pop :: Stack a -> (a, Stack a)
;pop (MkStack x s)
  = (x, case s of {r -> i r where {i x = x}}) -- (pop Empty) is an error

;top :: Stack a -> a
;top (MkStack x s) = x -- (top Empty) is an error
}
EOS

my $long_explicit_ast = [
    'module', 'module', 'AStack',
    [
        '(',
        [
            [ 'export', 'Stack' ],
            [ 'export', [ 'qvar', 'push' ] ],
            [ 'export', [ 'qvar', 'pop' ] ],
            [ 'export', [ 'qvar', 'top' ] ],
            [ 'export', [ 'qvar', 'size' ] ]
        ],
        ')'
    ],
    'where',
    [
        [
            'body',
            [
                'topdecls',
                [
                    'topdecl',
                    'data',
                    [ 'simpletype', 'Stack', [ 'tyvars', 'a' ] ],
                    '=',
                    [
                        'constrs',
                        [ 'constr', [ 'con', 'Empty' ], [] ],
                        [
                            'constr',
                            [ 'con', 'MkStack' ],
                            [
                                [ ['optBang'], [ 'atype', 'a' ] ],
                                [
                                    ['optBang'],
                                    [
                                        'atype', '(',
                                        [
                                            'type',
                                            [
                                                'btype',
                                                [
                                                    'btype',
                                                    [
                                                        'atype',
                                                        [ 'gtycon', 'Stack' ]
                                                    ]
                                                ],
                                                [ 'atype', 'a' ]
                                            ]
                                        ],
                                        ')'
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'gendecl',
                            [ 'vars', [ 'var', 'push' ] ],
                            '::',
                            [
                                'type',
                                [ 'btype', [ 'atype', 'a' ] ],
                                '->',
                                [
                                    'type',
                                    [
                                        'btype',
                                        [
                                            'btype',
                                            [ 'atype', [ 'gtycon', 'Stack' ] ]
                                        ],
                                        [ 'atype', 'a' ]
                                    ],
                                    '->',
                                    [
                                        'type',
                                        [
                                            'btype',
                                            [
                                                'btype',
                                                [
                                                    'atype',
                                                    [ 'gtycon', 'Stack' ]
                                                ]
                                            ],
                                            [ 'atype', 'a' ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'funlhs',
                            [ 'var', 'push' ],
                            [
                                [ 'apat', [ 'var', 'x' ] ],
                                [ 'apat', [ 'var', 's' ] ]
                            ]
                        ],
                        [
                            'rhs', '=',
                            [
                                'exp',
                                [
                                    'infixexp',
                                    [
                                        'lexp',
                                        [
                                            'fexp',
                                            [
                                                'fexp',
                                                [
                                                    'fexp',
                                                    [
                                                        'aexp',
                                                        [
                                                            'gcon',
                                                            [
                                                                'qcon',
                                                                'MkStack'
                                                            ]
                                                        ]
                                                    ]
                                                ],
                                                [ 'aexp', [ 'qvar', 'x' ] ]
                                            ],
                                            [ 'aexp', [ 'qvar', 's' ] ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'gendecl',
                            [ 'vars', [ 'var', 'size' ] ],
                            '::',
                            [
                                'type',
                                [
                                    'btype',
                                    [
                                        'btype',
                                        [ 'atype', [ 'gtycon', 'Stack' ] ]
                                    ],
                                    [ 'atype', 'a' ]
                                ],
                                '->',
                                [
                                    'type',
                                    [
                                        'btype',
                                        [ 'atype', [ 'gtycon', 'Int' ] ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'funlhs',
                            [ 'var', 'size' ],
                            [ [ 'apat', [ 'var', 's' ] ] ]
                        ],
                        [
                            'rhs', '=',
                            [
                                'exp',
                                [
                                    'infixexp',
                                    [
                                        'lexp',
                                        [
                                            'fexp',
                                            [
                                                'fexp',
                                                [
                                                    'aexp', [ 'qvar', 'length' ]
                                                ]
                                            ],
                                            [
                                                'aexp', '(',
                                                [
                                                    'exp',
                                                    [
                                                        'infixexp',
                                                        [
                                                            'lexp',
                                                            [
                                                                'fexp',
                                                                [
                                                                    'fexp',
                                                                    [
                                                                        'aexp',
                                                                        [
'qvar',
'stkToLst'
                                                                        ]
                                                                    ]
                                                                ],
                                                                [
                                                                    'aexp',
                                                                    [
                                                                        'qvar',
                                                                        's'
                                                                    ]
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ],
                                                ')'
                                            ]
                                        ]
                                    ]
                                ]
                            ],
                            'where',
                            [
                                [
                                    'decls',
                                    [
                                        'decl',
                                        [
                                            'funlhs',
                                            [ 'var', 'stkToLst' ],
                                            [
                                                [
                                                    'apat',
                                                    [
                                                        'gcon',
                                                        [ 'qcon', 'Empty' ]
                                                    ]
                                                ]
                                            ]
                                        ],
                                        [
                                            'rhs', '=',
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
                                                                    'gcon',
                                                                    '[]'
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
                                            [ 'var', 'stkToLst' ],
                                            [
                                                [
                                                    'apat', '(',
                                                    [
                                                        'pat',
                                                        [
                                                            'lpat',
                                                            [
                                                                'gcon',
                                                                [
                                                                    'qcon',
                                                                    'MkStack'
                                                                ]
                                                            ],
                                                            [
                                                                [
                                                                    'apat',
                                                                    [
                                                                        'var',
                                                                        'x'
                                                                    ]
                                                                ],
                                                                [
                                                                    'apat',
                                                                    [
                                                                        'var',
                                                                        's'
                                                                    ]
                                                                ]
                                                            ]
                                                        ]
                                                    ],
                                                    ')'
                                                ]
                                            ]
                                        ],
                                        [
                                            'rhs', '=',
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
                                                                [ 'qvar', 'x' ]
                                                            ]
                                                        ]
                                                    ],
                                                    [
                                                        'qop',
                                                        [
                                                            'qconop',
                                                            [ 'gconsym', ':' ]
                                                        ]
                                                    ],
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
                                                                        'xs'
                                                                    ]
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ]
                                            ],
                                            'where',
                                            [
                                                [
                                                    'decls',
                                                    [
                                                        'decl',
                                                        [
                                                            'funlhs',
                                                            [ 'var', 'xs' ],
                                                            []
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
'fexp',
                                                                                [
'aexp',
                                                                                    [
'qvar',
'stkToLst'
                                                                                    ]
                                                                                ]
                                                                            ],
                                                                            [
'aexp',
                                                                                [
'qvar',
's'
                                                                                ]
                                                                            ]
                                                                        ]
                                                                    ]
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ],
                                            ]
                                        ]
                                    ]
                                ],
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'gendecl',
                            [ 'vars', [ 'var', 'pop' ] ],
                            '::',
                            [
                                'type',
                                [
                                    'btype',
                                    [
                                        'btype',
                                        [ 'atype', [ 'gtycon', 'Stack' ] ]
                                    ],
                                    [ 'atype', 'a' ]
                                ],
                                '->',
                                [
                                    'type',
                                    [
                                        'btype',
                                        [
                                            'atype', '(',
                                            [
                                                [
                                                    [
                                                        'type',
                                                        [
                                                            'btype',
                                                            [ 'atype', 'a' ]
                                                        ]
                                                    ],
                                                    ',',
                                                    [
                                                        'type',
                                                        [
                                                            'btype',
                                                            [
                                                                'btype',
                                                                [
                                                                    'atype',
                                                                    [
'gtycon',
                                                                        'Stack'
                                                                    ]
                                                                ]
                                                            ],
                                                            [ 'atype', 'a' ]
                                                        ]
                                                    ]
                                                ]
                                            ],
                                            ')'
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'funlhs',
                            [ 'var', 'pop' ],
                            [
                                [
                                    'apat', '(',
                                    [
                                        'pat',
                                        [
                                            'lpat',
                                            [ 'gcon', [ 'qcon', 'MkStack' ] ],
                                            [
                                                [ 'apat', [ 'var', 'x' ] ],
                                                [ 'apat', [ 'var', 's' ] ]
                                            ]
                                        ]
                                    ],
                                    ')'
                                ]
                            ]
                        ],
                        [
                            'rhs', '=',
                            [
                                'exp',
                                [
                                    'infixexp',
                                    [
                                        'lexp',
                                        [
                                            'fexp',
                                            [
                                                'aexp', '(',
                                                [
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
                                                    ],
                                                    ',',
                                                    [
                                                        'exp',
                                                        [
                                                            'infixexp',
                                                            [
                                                                'lexp',
                                                                'case',
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
's'
                                                                                    ]
                                                                                ]
                                                                            ]
                                                                        ]
                                                                    ]
                                                                ],
                                                                'of',
                                                                [
                                                                    [
                                                                        'alts',
                                                                        [
'alt',
                                                                            [
'pat',
                                                                                [
'lpat',
                                                                                    [
'apat',
                                                                                        [
'var',
'r'
                                                                                        ]
                                                                                    ]
                                                                                ]
                                                                            ],
'->',
                                                                            [
'exp',
                                                                                [
'infixexp',
                                                                                    [
'lexp',
                                                                                        [
'fexp',
                                                                                            [
'fexp',
                                                                                                [
'aexp',
                                                                                                    [
'qvar',
'i'
                                                                                                    ]
                                                                                                ]
                                                                                            ]
                                                                                            ,
                                                                                            [
'aexp',
                                                                                                [
'qvar',
'r'
                                                                                                ]
                                                                                            ]
                                                                                        ]
                                                                                    ]
                                                                                ]
                                                                            ],
'where',
                                                                            [
                                                                                [
'decls',
                                                                                    [
'decl',
                                                                                        [
'funlhs',
                                                                                            [
'var',
'i'
                                                                                            ]
                                                                                            ,
                                                                                            [
                                                                                                [
'apat',
                                                                                                    [
'var',
'x'
                                                                                                    ]
                                                                                                ]
                                                                                            ]
                                                                                        ]
                                                                                        ,
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
                                                                            ]
                                                                        ]
                                                                    ],
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ],
                                                ')'
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'gendecl',
                            [ 'vars', [ 'var', 'top' ] ],
                            '::',
                            [
                                'type',
                                [
                                    'btype',
                                    [
                                        'btype',
                                        [ 'atype', [ 'gtycon', 'Stack' ] ]
                                    ],
                                    [ 'atype', 'a' ]
                                ],
                                '->',
                                [ 'type', [ 'btype', [ 'atype', 'a' ] ] ]
                            ]
                        ]
                    ]
                ],
                [
                    'topdecl',
                    [
                        'decl',
                        [
                            'funlhs',
                            [ 'var', 'top' ],
                            [
                                [
                                    'apat', '(',
                                    [
                                        'pat',
                                        [
                                            'lpat',
                                            [ 'gcon', [ 'qcon', 'MkStack' ] ],
                                            [
                                                [ 'apat', [ 'var', 'x' ] ],
                                                [ 'apat', [ 'var', 's' ] ]
                                            ]
                                        ]
                                    ],
                                    ')'
                                ]
                            ]
                        ],
                        [
                            'rhs', '=',
                            [
                                'exp',
                                [
                                    'infixexp',
                                    [
                                        'lexp',
                                        [ 'fexp', [ 'aexp', [ 'qvar', 'x' ] ] ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
];

my $long_explicit_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($long_explicit_ast) );

local $main::DEBUG = 0;

doTest( \$long_explicit, $long_explicit_expected );
doTest( \$long_implicit, $long_explicit_expected );
$main::DEBUG = 0;

sub doTest {
    my ($inputRef, $expected_value ) = @_;
    my ($result, $valueRef) = MarpaX::R2::Haskell::topParser($inputRef);
    if ( $result ne 'OK' ) {
        Test::More::fail(qq{Result was "$result", not OK});
        Test::More::fail(qq{No value test, because result was not OK});
        return
    }
    Test::More::pass(qq{Result is OK});
    my $value = '[fail]';
    if ($valueRef) {
        $value = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($valueRef) );
    }
    Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
}
