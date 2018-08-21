#!/usr/bin/perl)

# Examples from the Gentle Introduction to Haskell.

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;
use English qw( -no_match_vars );

use Test::More tests => 8;
use Test::Differences;

use Marpa::R2 4.000;

require "haskell.pm";

my $short_implicit = <<'EOS';
main =
 let y   = a*b
     f x = (x+y)/y
 in f c + f d
EOS

my $short_explicit = <<'EOS';
main =
 let { y   = a*b
     ; f x = (x+y)/y
     }
 in f c + f d
EOS

my $short_alt = <<'EOS';
main =
 let y   = a*b f
     x   = (x+y)/y
 in f c + f d
EOS

my $short_mixed = <<'EOS';
main =
 let y   = a*b;  z = a/b
     f x = (x+y)/z
 in f c + f d
EOS

my $short_implicit_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
			    ], [] ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'a'
				      ] ] ] ], [ 'qop', [ 'qvarop', '*'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'b'
					] ] ] ] ] ] ] ] ],
			[ 'decl', [ 'funlhs',
			    [ 'var', 'f'
			    ], [ 'apat', [ 'var', 'x'
				] ],
			    ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', '(',
				      [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'x'
						] ] ] ],
					  [ 'qop', [ 'qvarop', '+'
					    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
						  ] ] ] ] ] ] ], ')'
				    ] ] ], [ 'qop', [ 'qvarop', '/'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
					] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_implicit_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($short_implicit_ast) );

my $short_mixed_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
			    ], [] ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'a'
				      ] ] ] ], [ 'qop', [ 'qvarop', '*'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'b'
					] ] ] ] ] ] ] ] ],

			[ 'decl', [ 'funlhs',
                   [ 'var', 'z'
                   ], [] ], [ 'rhs', '=',
                   [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'a'
                             ] ] ] ], [ 'qop', [ 'qvarop', '/'
                         ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'b'
                               ] ] ] ] ] ] ] ] ],

			[ 'decl', [ 'funlhs',
			    [ 'var', 'f'
			    ], [ 'apat', [ 'var', 'x'
				] ],
			    ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', '(',
				      [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'x'
						] ] ] ],
					  [ 'qop', [ 'qvarop', '+'
					    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
						  ] ] ] ] ] ] ], ')'
				    ] ] ], [ 'qop', [ 'qvarop', '/'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'z'
					] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_mixed_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($short_mixed_ast) );

my $short_alt_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
			    ], [] ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'a'
				      ] ] ] ], [ 'qop', [ 'qvarop', '*'
				  ] ],
			       [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'b'
					 ] ] ], [ 'aexp', [ 'qvar', 'f' ] ] ] ] ]
					] ] ] ],
			[ 'decl', [ 'funlhs', [ 'var', 'x'
			    ], [] ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', '(',
				      [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'x'
						] ] ] ],
					  [ 'qop', [ 'qvarop', '+'
					    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
						  ] ] ] ] ] ] ], ')'
				    ] ] ], [ 'qop', [ 'qvarop', '/'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
					] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_alt_expected = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($short_alt_ast) );

local $main::DEBUG = 0;

doTest( \$short_implicit, $short_implicit_expected );
doTest( \$short_mixed, $short_mixed_expected );
doTest( \$short_alt, $short_alt_expected );
doTest( \$short_explicit, $short_implicit_expected );
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

    say "===\n", Data::Dumper::Dumper(
    MarpaX::R2::Haskell::pruneNodes($valueRef) ), "===\n";

        $value = Data::Dumper::Dumper( MarpaX::R2::Haskell::pruneNodes($$valueRef) );
    }
    Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
}
