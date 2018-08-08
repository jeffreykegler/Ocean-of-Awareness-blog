#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );

use Test::More tests => 24;

use Marpa::R2 4.000;

my $dsl = <<'END_OF_DSL';
lexeme default = latm => 1
:default ::= action => [name,start,length,values]

# module	→	module modid [exports] where body 
# |	body

module ::= resword_module L0_modid optExports resword_where body
         | body

optExports ::= '(' exports ')'
optExports ::= # empty

# body	→	{ impdecls ; topdecls }
# |	{ impdecls }
# |	{ topdecls }

body ::= topdecls

# impdecls	→	impdecl1 ; … ; impdecln	    (n ≥ 1)
#  
# exports	→	( export1 , … , exportn [ , ] )	    (n ≥ 0)

exports ::= export* separator => [,]

# export	→	qvar
# |	qtycon [(..) | ( cname1 , … , cnamen )]	    (n ≥ 0)
# |	qtycls [(..) | ( qvar1 , … , qvarn )]	    (n ≥ 0)
# |	module modid

export ::= qvar
export ::= qtycon
export ::= qtycls

#  
# impdecl	→	import [qualified] modid [as modid] [impspec]
# |		    (empty declaration)
#  
# impspec	→	( import1 , … , importn [ , ] )	    (n ≥ 0)
# |	hiding ( import1 , … , importn [ , ] )	    (n ≥ 0)
#  
# import	→	var
# |	tycon [ (..) | ( cname1 , … , cnamen )]	    (n ≥ 0)
# |	tycls [(..) | ( var1 , … , varn )]	    (n ≥ 0)
# cname	→	var | con
#  
# topdecls	→	topdecl1 ; … ; topdecln	    (n ≥ 0)

topdecls ::= topdecl*

# topdecl	→	type simpletype = type
# |	data [context =>] simpletype [= constrs] [deriving]

topdecl ::= resword_data simpletype '=' constrs

# |	newtype [context =>] simpletype = newconstr [deriving]
# |	class [scontext =>] tycls tyvar [where cdecls]
# |	instance [scontext =>] qtycls inst [where idecls]
#	|	default (type1 , … , typen)	    (n ≥ 0)
#|	foreign fdecl
#|	decl
# 
#decls	→	{ decl1 ; … ; decln }	    (n ≥ 0)
#decl	→	gendecl
#|	(funlhs | pat) rhs
#
# decls	→	{ cdecl1 ; … ; cdecln }	    (n ≥ 0)
# cdecl	→	gendecl
# |	(funlhs | var) rhs
#  
# idecls	→	{ idecl1 ; … ; idecln }	    (n ≥ 0)
# idecl	→	(funlhs | var) rhs
# |		    (empty)
#  
# gendecl	→	vars :: [context =>] type	    (type signature)
# |	fixity [integer] ops	    (fixity declaration)
# |		    (empty declaration)
#  
# ops	→	op1 , … , opn	    (n ≥ 1)
# vars	→	var1 , …, varn	    (n ≥ 1)
# fixity	→	infixl | infixr | infix

# type	→	btype [-> type]	    (function type)

type ::= btype '->' type | btype

# btype	→	[btype] atype	    (type application)

btype ::= btype atype | atype

# atype	→	gtycon
# |	tyvar
# |	( type1 , … , typek )	    (tuple type, k ≥ 2)
# |	[ type ]	    (list type)
# |	( type )	    (parenthesized constructor)

atype ::= gtycon
atype ::= tyvar
atype ::= '(' type ')'

# gtycon	→	qtycon
# |	()	    (unit type)
# |	[]	    (list constructor)
# |	(->)	    (function constructor)
# |	(,{,})	    (tupling constructors)

gtycon ::= qtycon

# context	→	class
# |	( class1 , … , classn )	    (n ≥ 0)
# class	→	qtycls tyvar
# |	qtycls ( tyvar atype1 … atypen )	    (n ≥ 1)
# scontext	→	simpleclass
# |	( simpleclass1 , … , simpleclassn )	    (n ≥ 0)
# simpleclass	→	qtycls tyvar
#  
# simpletype	→	tycon tyvar1 … tyvark	    (k ≥ 0)

simpletype ::= L0_tycon tyvars
tyvars ::= tyvar*

# constrs	→	constr1 | … | constrn	    (n ≥ 1)

constrs ::= constr+ separator => [|]

# constr	→	con [!] atype1 … [!] atypek	    (arity con  =  k, k ≥ 0)
# |	(btype | ! atype) conop (btype | ! atype)	    (infix conop)
# |	con { fielddecl1 , … , fielddecln }	    (n ≥ 0)

constr ::= con flagged_atypes
flagged_atypes ::= flagged_atype*
flagged_atype  ::= optBang atype
optBang ::= '!'
optBang ::= # empty

# newconstr	→	con atype
# |	con { var :: type }
# fielddecl	→	vars :: (type | ! atype)
# deriving	→	deriving (dclass | (dclass1, … , dclassn))	    (n ≥ 0)
# dclass	→	qtycls
#  
# inst	→	gtycon
# |	( gtycon tyvar1 … tyvark )	    (k ≥ 0, tyvars distinct)
# |	( tyvar1 , … , tyvark )	    (k ≥ 2, tyvars distinct)
# |	[ tyvar ]
# |	( tyvar1 -> tyvar2 )	    tyvar1 and tyvar2 distinct
#  
# fdecl	→	import callconv [safety] impent var :: ftype	    (define variable)
# |	export callconv expent var :: ftype	    (expose variable)
# callconv	→	ccall | stdcall | cplusplus	    (calling convention)
# |	jvm | dotnet
# |	 system-specific calling conventions
# impent	→	[string]	    (see Section 8.5.1)
# expent	→	[string]	    (see Section 8.5.1)
# safety	→	unsafe | safe
#  
# ftype	→	frtype
# |	fatype  →  ftype
# frtype	→	fatype
# |	()
# fatype	→	qtycon atype1 … atypek	    (k  ≥  0)
#  
# funlhs	→	var apat { apat }
# |	pat varop pat
# |	( funlhs ) apat { apat }
#  
# rhs	→	= exp [where decls]
# |	gdrhs [where decls]
#  
# gdrhs	→	guards = exp [gdrhs]
#  
# guards	→	| guard1, …, guardn	    (n ≥ 1)
# guard	→	pat <- infixexp	    (pattern guard)
# |	let decls	    (local declaration)
# |	infixexp	    (boolean guard)
#  
# exp	→	infixexp :: [context =>] type	    (expression type signature)
# |	infixexp
#  
# infixexp	→	lexp qop infixexp	    (infix operator application)
# |	- infixexp	    (prefix negation)
# |	lexp
#  
# lexp	→	\ apat1 … apatn -> exp	    (lambda abstraction, n ≥ 1)
# |	let decls in exp	    (let expression)
# |	if exp [;] then exp [;] else exp	    (conditional)
# |	case exp of { alts }	    (case expression)
# |	do { stmts }	    (do expression)
# |	fexp
# fexp	→	[fexp] aexp	    (function application)
#  
# aexp	→	qvar	    (variable)
# |	gcon	    (general constructor)
# |	literal
# |	( exp )	    (parenthesized expression)
# |	( exp1 , … , expk )	    (tuple, k ≥ 2)
# |	[ exp1 , … , expk ]	    (list, k ≥ 1)
# |	[ exp1 [, exp2] .. [exp3] ]	    (arithmetic sequence)
# |	[ exp | qual1 , … , qualn ]	    (list comprehension, n ≥ 1)
# |	( infixexp qop )	    (left section)
# |	( qop⟨-⟩ infixexp )	    (right section)
# |	qcon { fbind1 , … , fbindn }	    (labeled construction, n ≥ 0)
# |	aexp⟨qcon⟩ { fbind1 , … , fbindn }	    (labeled update, n  ≥  1)
#  
# qual	→	pat <- exp	    (generator)
# |	let decls	    (local declaration)
# |	exp	    (guard)
#  
# alts	→	alt1 ; … ; altn	    (n ≥ 1)
# alt	→	pat -> exp [where decls]
# |	pat gdpat [where decls]
# |		    (empty alternative)
#  
# gdpat	→	guards -> exp [ gdpat ]
#  
# stmts	→	stmt1 … stmtn exp [;]	    (n ≥ 0)
# stmt	→	exp ;
# |	pat <- exp ;
# |	let decls ;
# |	;	    (empty statement)
#  
# fbind	→	qvar = exp
#  
# pat	→	lpat qconop pat	    (infix constructor)
# |	lpat
#  
# lpat	→	apat
# |	- (integer | float)	    (negative literal)
# |	gcon apat1 … apatk	    (arity gcon  =  k, k ≥ 1)
#  
# apat	→	var [ @ apat]	    (as pattern)
# |	gcon	    (arity gcon  =  0)
# |	qcon { fpat1 , … , fpatk }	    (labeled pattern, k ≥ 0)
# |	literal
# |	_	    (wildcard)
# |	( pat )	    (parenthesized pattern)
# |	( pat1 , … , patk )	    (tuple pattern, k ≥ 2)
# |	[ pat1 , … , patk ]	    (list pattern, k ≥ 1)
# |	~ apat	    (irrefutable pattern)
#  
# fpat	→	qvar = pat
#  
# gcon	→	()
# |	[]
# |	(,{,})
# |	qcon
#  
# var	→	varid | ( varsym )	    (variable)
# qvar	→	qvarid | ( qvarsym )	    (qualified variable)

qvar ::= qvarid
       | '(' qvarsym ')'

# con	→	conid | ( consym )	    (constructor)

con ::= L0_conid
       | '(' L0_consym ')'

# qcon	→	qconid | ( gconsym )	    (qualified constructor)
# varop	→	varsym | `  varid `	    (variable operator)
# qvarop	→	qvarsym | `  qvarid `	    (qualified variable operator)
# conop	→	consym | `  conid `	    (constructor operator)
# qconop	→	gconsym | `  qconid `	    (qualified constructor operator)
# op	→	varop | conop	    (operator)
# qop	→	qvarop | qconop	    (qualified operator)
# gconsym	→	: | qconsym

# Lexical syntax from Section 10.2

# prgram	→	{ lexeme | whitespace }
# lexeme	→	qvarid | qconid | qvarsym | qconsym
# |	literal | special | reservedop | reservedid
# literal	→	integer | float | char | string
# special	→	( | ) | , | ; | [ | ] | ` | { | }
#  
# whitespace	→	whitestuff {whitestuff}
# whitestuff	→	whitechar | comment | ncomment
# whitechar	→	newline | vertab | space | tab | uniWhite
# newline	→	return linefeed | return | linefeed | formfeed
# return	→	a carriage return
# linefeed	→	a line feed
# vertab	→	a vertical tab
# formfeed	→	a form feed

:discard ~ whitestuff
whitestuff ~ whitechars
whitechars ~ whitechar+
whitestuff ~ comment
whitechar ~ [\s]

# space	→	a space
# tab	→	a horizontal tab
# uniWhite	→	any Unicode character defined as whitespace
#  
# comment	→	dashes [ any⟨symbol⟩ {any} ] newline

comment ~ '--' nonNewlines '\n'
nonNewlines ~ nonNewline*
nonNewline ~ [^\n]

# dashes	→	-- {-}
# opencom	→	{-
# closecom	→	-}
# ncomment	→	opencom ANY seq {ncomment ANY seq} closecom
# ANY seq	→	{ANY }⟨{ANY } ( opencom | closecom ) {ANY }⟩
# ANY	→	graphic | whitechar
# any	→	graphic | space | tab
# graphic	→	small | large | symbol | digit | special | " | '
#  
# small	→	ascSmall | uniSmall | _

small ~ ascSmall | '_'

# ascSmall	→	a | b | … | z

ascSmall ~ [a-z]

# uniSmall	→	any Unicode lowercase letter
#  
# large	→	ascLarge | uniLarge

large ~ ascLarge

# ascLarge	→	A | B | … | Z

ascLarge ~ [A-Z]

# uniLarge	→	any uppercase or titlecase Unicode letter
# symbol	→	ascSymbol | uniSymbol⟨special | _ | " | '⟩

symbol ~ ascSymbol
nonColonSymbol ~ nonColonAscSymbol

#  
# ascSymbol	→	! | # | $ | % | & | ⋆ | + | . | / | < | = | > | ? | @

nonColonAscSymbol ~ '!' | '#' | '$' | '%' | '&' | '+' | '.' | '/' | '<' | '=' | '>' | '?' | '@'
colon ~ ':'
ascSymbol ~ colon | nonColonAscSymbol

# |	\ | ^ | | | - | ~ | :
# uniSymbol	→	any Unicode symbol or punctuation
# digit	→	ascDigit | uniDigit

digit ~ [0-9]

# ascDigit	→	0 | 1 | … | 9
# uniDigit	→	any Unicode decimal digit
# octit	→	0 | 1 | … | 7
# hexit	→	digit | A | … | F | a | … | f
#  
# varid	→	(small {small | large | digit | ' })⟨reservedid⟩

varid ~ small nonInitials
nonInitials ~ nonInitial*
nonInitial ~ small | large | digit | [']

# conid	→	large {small | large | digit | ' }

:lexeme ~ L0_conid
L0_conid ~ large nonInitials
conid ~ large nonInitials

# reservedid	→	case | class | data | default | deriving | do | else
# |	foreign | if | import | in | infix | infixl
# |	infixr | instance | let | module | newtype | of
# |	then | type | where | _

# :lexeme ~ resword_case priority => 1
# resword_case ~ 'case'
# :lexeme ~ resword_class priority => 1
# resword_class ~ 'class'
:lexeme ~ resword_data priority => 1
resword_data ~ 'data'
# :lexeme ~ resword_default priority => 1
# resword_default ~ 'default'
# :lexeme ~ resword_deriving priority => 1
# resword_deriving ~ 'deriving'
# :lexeme ~ resword_do priority => 1
# resword_do ~ 'do'
# :lexeme ~ resword_else priority => 1
# resword_else ~ 'else'
# :lexeme ~ resword_foreign priority => 1
# resword_foreign ~ 'foreign'
# :lexeme ~ resword_if priority => 1
# resword_if ~ 'if'
# :lexeme ~ resword_import priority => 1
# resword_import ~ 'import'
# :lexeme ~ resword_in priority => 1
# resword_in ~ 'in'
# :lexeme ~ resword_infix priority => 1
# resword_infix ~ 'infix'
# :lexeme ~ resword_infixl priority => 1
# resword_infixl ~ 'infixl'
# :lexeme ~ resword_infixr priority => 1
# resword_infixr ~ 'infixr'
# :lexeme ~ resword_instance priority => 1
# resword_instance ~ 'instance'
# :lexeme ~ resword_let priority => 1
# resword_let ~ 'let'
:lexeme ~ resword_module priority => 1
resword_module ~ 'module'
# :lexeme ~ resword_newtype priority => 1
# resword_newtype ~ 'newtype'
# :lexeme ~ resword_of priority => 1
# resword_of ~ 'of'
# :lexeme ~ resword_then priority => 1
# resword_then ~ 'then'
# :lexeme ~ resword_type priority => 1
# resword_type ~ 'type'
:lexeme ~ resword_where priority => 1
resword_where ~ 'where'
# :lexeme ~ resword_underscore priority => 1
# resword_underscore ~ '_'

#  
# varsym	→	( symbol⟨:⟩ {symbol} )⟨reservedop | dashes⟩

varsym ~ nonColonSymbol symbols
symbols ~ symbol+

# consym	→	( : {symbol})⟨reservedop⟩

:lexeme ~ L0_consym
L0_consym ~ ':' symbols

# reservedop	→	.. | : | :: | = | \ | | | <- | -> |  @ | ~ | =>
#  
# varid	    	    (variables)
# conid	    	    (constructors)
# tyvar	→	varid	    (type variables)

tyvar ~ varid

# tycon	→	conid	    (type constructors)

:lexeme ~ L0_tycon
L0_tycon ~ tycon
tycon ~ conid

# tycls	→	conid	    (type classes)

tycls ~ conid

# modid	→	{conid .} conid	    (modules)

:lexeme ~ L0_modid
L0_modid ~ modid
modid ~ conid | modid '.' conid

#  
# qvarid	→	[ modid . ] varid

qvarid ~ modid '.' varid | varid

# qconid	→	[ modid . ] conid
# qtycon	→	[ modid . ] tycon

qtycon ~ modid '.' tycon | tycon

# qtycls	→	[ modid . ] tycls

qtycls ~ modid '.' tycls | tycls

# qvarsym	→	[ modid . ] varsym

qvarsym ~ modid '.' varsym | varsym

# qconsym	→	[ modid . ] consym
#  
# decimal	→	digit{digit}
# octal	→	octit{octit}
# hexadecimal	→	hexit{hexit}
#  
# integer	→	decimal
# |	0o octal | 0O octal
# |	0x hexadecimal | 0X hexadecimal
# float	→	decimal . decimal [exponent]
# |	decimal exponent
# exponent	→	(e | E) [+ | -] decimal
#  
# char	→	' (graphic⟨' | \⟩ | space | escape⟨\&⟩) '
# string	→	" {graphic⟨" | \⟩ | space | escape | gap} "
# escape	→	\ ( charesc | ascii | decimal | o octal | x hexadecimal )
# charesc	→	a | b | f | n | r | t | v | \ | " | ' | &
# ascii	→	^cntrl | NUL | SOH | STX | ETX | EOT | ENQ | ACK
# |	BEL | BS | HT | LF | VT | FF | CR | SO | SI | DLE
# |	DC1 | DC2 | DC3 | DC4 | NAK | SYN | ETB | CAN
# |	EM | SUB | ESC | FS | GS | RS | US | SP | DEL
# cntrl	→	ascLarge | @ | [ | \ | ] | ^ | _
# gap	→	\ whitechar {whitechar} \

END_OF_DSL

my $input = <<'EOS';
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

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

{
    my $expected_result = '';
    my $expected_value = '';
    my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar,
       trace_terminals => 99,
       # trace_lexers => 1,
    } );
    my $value_ref;
    my $result = 'OK';
    my $eval_ok = eval { $value_ref = doit( $recce, \$input ); 1; };
    if ( !$eval_ok ) {
	my $eval_error = $EVAL_ERROR;
	PARSE_EVAL_ERROR: {
	  $result = "Error: $EVAL_ERROR";
	  Test::More::diag($result);
	}
    }
    if ($result ne $expected_result) {
        Test::More::fail(qq{Result was "$result"; expected "$expected_result"});
    } else {
      Test::More::pass(qq{Result matches});
    }
    my $value = '[fail]';
    if ($value_ref) {
       $value = Data::Dumper::Dumper($value_ref);
    }
    if ($value ne $expected_value) {
        Test::More::fail(qq{Test of value was "$value"; expected "$expected_value"});
    } else {
      Test::More::pass(qq{Value matches});
    }
} ## end TEST:

sub doit {
    my ( $recce, $input ) = @_;
    my $input_length = length ${$input};
    for (
        my $pos = $recce->read($input);
        $pos < $input_length;
        $pos = $recce->resume()
      )
    {
      EVENT:
        for (
            my $event_ix = 0 ;
            my $event    = $recce->event($event_ix) ;
            $event_ix++
          )
        {
            my $name = $event->[0];
	    die qq{Unexpected event: name="$name"};
        }
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        die "input read, but there was no parse";
    }

    return $value_ref;
}