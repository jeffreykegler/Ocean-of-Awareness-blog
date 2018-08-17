#!/usr/bin/perl)

use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;
use English qw( -no_match_vars );

use Test::More tests => 10;
use Test::Differences;

use Marpa::R2 4.000;

sub divergence {
    die join '', 'Unrecoverable internal error: ', @_;
}

my $dsl = <<'END_OF_DSL';
lexeme default = latm => 1
:default ::= action => [name,values]

# module	→	module modid [exports] where body 
# |	body

module ::= resword_module L0_modid optExports resword_where laidout_body
         | body

laidout_body ::= ('{') ruby_x_body ('}')
	 | ruby_i_body
	 # The next line is a fake, to fool the parser into thinking
	 # that <body> is accessible.  <unicorn> will
	 # never be found in any input.
	 | L0_unicorn body L0_unicorn

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

topdecls ::= topdecl* separator => virtual_semicolon

virtual_semicolon ::= ruby_semicolon
virtual_semicolon ::= L0_semicolon

# topdecl	→	type simpletype = type
# |	data [context =>] simpletype [= constrs] [deriving]
# |	newtype [context =>] simpletype = newconstr [deriving]
# |	class [scontext =>] tycls tyvar [where cdecls]
# |	instance [scontext =>] qtycls inst [where idecls]
#	|	default (type1 , … , typen)	    (n ≥ 0)
#|	foreign fdecl
#|	decl

topdecl ::= resword_data simpletype '=' constrs
topdecl ::= decl

#decls	→	{ decl1 ; … ; decln }	    (n ≥ 0)
#decl	→	gendecl
#|	(funlhs | pat) rhs

# Not an explicit sequence, to allow for a nullable
# separator.
decls ::= decl* separator => virtual_semicolon
decl ::= gendecl
decl ::= funlhs rhs

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

gendecl ::= vars '::' type

# ops	→	op1 , … , opn	    (n ≥ 1)
# vars	→	var1 , …, varn	    (n ≥ 1)

vars ::= var+

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
atype ::= '(' tuple_type_list ')'
atype ::= '(' type ')'

tuple_type_list ::= duple_type_list
tuple_type_list ::= duple_type_list L0_comma type
duple_type_list ::= type L0_comma type

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

funlhs ::= var apats
funlhs ::= pat varop pat
funlhs ::= '(' funlhs ')' apats
apats  ::= apat*
apats1 ::= apat+

#  
# rhs	→	= exp [where decls]
# |	gdrhs [where decls]

rhs ::= '=' exp
rhs ::= '=' exp resword_where laidout_decls

laidout_decls ::= ('{') ruby_x_decls ('}')
	 | ruby_i_decls
	 # The next line is a fake, to fool the parser into thinking
	 # that <decls> is accessible.  <unicorn> will
	 # never be found in any input.
	 | L0_unicorn decls L0_unicorn
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

exp ::= infixexp

# infixexp	→	lexp qop infixexp	    (infix operator application)
# |	- infixexp	    (prefix negation)
# |	lexp

infixexp ::= lexp qop infixexp
infixexp ::= '-' infixexp
infixexp ::= lexp

# lexp	→	\ apat1 … apatn -> exp	    (lambda abstraction, n ≥ 1)
# |	let decls in exp	    (let expression)
# |	if exp [;] then exp [;] else exp	    (conditional)
# |	case exp of { alts }	    (case expression)
# |	do { stmts }	    (do expression)
# |	fexp

lexp ::= fexp
lexp ::= resword_let laidout_decls resword_in exp
lexp ::= resword_case exp resword_of laidout_alts

laidout_alts ::= ('{') ruby_x_alts ('}')
	 | ruby_i_alts
	 # The next line is a fake, to fool the parser into thinking
	 # that <alts> is accessible.  <unicorn> will
	 # never be found in any input.
	 | L0_unicorn alts L0_unicorn

# fexp	→	[fexp] aexp	    (function application)

fexp ::= fexp aexp
fexp ::= aexp

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

aexp ::= qvar
aexp ::= '(' exp ')'
aexp ::= '(' exp_tuple_list ')'
aexp ::= gcon

exp_tuple_list ::= exp L0_comma exp
exp_tuple_list ::= exp_tuple_list L0_comma exp

#  
# qual	→	pat <- exp	    (generator)
# |	let decls	    (local declaration)
# |	exp	    (guard)
#  
# alts	→	alt1 ; … ; altn	    (n ≥ 1)

# Explicit BNF recursion needed, 
# because Marpa's counted rules do not
# allow a RHS nullable, and <alt> is
# nullable
alts ::= alt
alts ::= alts virtual_semicolon alt

# alt	→	pat -> exp [where decls]
# |	pat gdpat [where decls]
# |		    (empty alternative)

alt ::= pat '->' exp
alt ::= pat '->' exp resword_where laidout_decls
alt ::= # empty

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

pat ::= lpat qconop pat
pat ::= lpat

#  
# lpat	→	apat
# |	- (integer | float)	    (negative literal)
# |	gcon apat1 … apatk	    (arity gcon  =  k, k ≥ 1)

lpat ::= apat
lpat ::= gcon apats1

# apat	→	var [ @ apat]	    (as pattern)
# |	gcon	    (arity gcon  =  0)
# |	qcon { fpat1 , … , fpatk }	    (labeled pattern, k ≥ 0)
# |	literal
# |	_	    (wildcard)
# |	( pat )	    (parenthesized pattern)
# |	( pat1 , … , patk )	    (tuple pattern, k ≥ 2)
# |	[ pat1 , … , patk ]	    (list pattern, k ≥ 1)
# |	~ apat	    (irrefutable pattern)

apat ::= var
apat ::= var '@' apat
apat ::= gcon
apat ::= '(' pat ')'

# fpat	→	qvar = pat
#  
# gcon	→	()
# |	[]
# |	(,{,})
# |	qcon

gcon ::= '()'
gcon ::= '[]'
gcon ::= '(' L0_commas ')'
gcon ::= qcon

# var	→	varid | ( varsym )	    (variable)

var ::= L0_varid | '(' L0_varsym ')'

# qvar	→	qvarid | ( qvarsym )	    (qualified variable)

qvar ::= qvarid | '(' qvarsym ')'

# con	→	conid | ( consym )	    (constructor)

con ::= L0_conid
       | '(' L0_consym ')'

# qcon	→	qconid | ( gconsym )	    (qualified constructor)

qcon ::= L0_qconid
       | '(' gconsym ')'

# varop	→	varsym | `  varid `	    (variable operator)

varop ::= L0_varsym | [`] L0_varid [`]

# qvarop	→	qvarsym | `  qvarid `	    (qualified variable operator)

qvarop ::= qvarsym | [`] qvarid [`]

# conop	→	consym | `  conid `	    (constructor operator)
# qconop	→	gconsym | `  qconid `	    (qualified constructor operator)

qconop ::= gconsym | [`] L0_qconid [`]

# op	→	varop | conop	    (operator)
# qop	→	qvarop | qconop	    (qualified operator)

qop ::= qvarop | qconop

# gconsym	→	: | qconsym

gconsym ::= L0_colon | L0_qconsym

# Lexical syntax from Section 10.2

# A unicorn is a lexeme which cannot occur.
# Unicorns are used as dummy RHSs for Ruby Slippers
# tokens
:lexeme ~ L0_unicorn
L0_unicorn ~ unicorn
unicorn ~ [^\d\D]
ruby_i_body ~ unicorn
ruby_x_body ~ unicorn
ruby_i_decls ~ unicorn
ruby_x_decls ~ unicorn
ruby_i_alts ~ unicorn
ruby_x_alts ~ unicorn

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

newline ~ [\n]

:lexeme ~ L0_commas
:lexeme ~ L0_comma
L0_commas ~ commas
L0_comma ~ comma
commas ~ comma*
comma ~ [,]

L0_semicolon ~ semicolon
ruby_semicolon ~ unicorn
semicolon ~ [;]

:discard ~ whitechars
whitechars ~ whitechar*
whitechar ~ [\t ]

:discard ~ comment
:discard ~ commentLine
commentLine ~ newline whitechars '--' nonNewlines

:discard ~ indent event => indent=off
indent ~ newline whitechars

# space	→	a space
# tab	→	a horizontal tab
# uniWhite	→	any Unicode character defined as whitespace
#  
# comment	→	dashes [ any⟨symbol⟩ {any} ] newline

comment ~ '--' nonNewlines
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

nonColonAscSymbol ~ '!' | '#' | '$' | '%' | '&'
  | '*' | '+' | '.' | '/' | '<' | '=' | '>' | '?' | '@'
  | '\' | '^' | '|' | '-' | '~'
:lexeme ~ L0_colon
L0_colon ~ colon
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

:lexeme ~ L0_varid
L0_varid ~ varid
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

:lexeme ~ resword_case priority => 1
resword_case ~ 'case'
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
:lexeme ~ resword_in priority => 1
resword_in ~ 'in'
# :lexeme ~ resword_infix priority => 1
# resword_infix ~ 'infix'
# :lexeme ~ resword_infixl priority => 1
# resword_infixl ~ 'infixl'
# :lexeme ~ resword_infixr priority => 1
# resword_infixr ~ 'infixr'
# :lexeme ~ resword_instance priority => 1
# resword_instance ~ 'instance'
:lexeme ~ resword_let priority => 1
resword_let ~ 'let'
:lexeme ~ resword_module priority => 1
resword_module ~ 'module'
# :lexeme ~ resword_newtype priority => 1
# resword_newtype ~ 'newtype'
:lexeme ~ resword_of priority => 1
resword_of ~ 'of'
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

:lexeme ~ L0_varsym
L0_varsym ~ varsym
varsym ~ nonColonSymbol symbols
symbols ~ symbol*

# consym	→	( : {symbol})⟨reservedop⟩

:lexeme ~ L0_consym
L0_consym ~ consym
consym ~ colon symbols

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

:lexeme ~ L0_qconid
L0_qconid ~ qconid
qconid ~ conid | modid '.' qconid

# qtycon	→	[ modid . ] tycon

qtycon ~ modid '.' tycon | tycon

# qtycls	→	[ modid . ] tycls

qtycls ~ modid '.' tycls | tycls

# qvarsym	→	[ modid . ] varsym

qvarsym ~ modid '.' varsym | varsym

# qconsym	→	[ modid . ] consym

:lexeme ~ L0_qconsym
L0_qconsym ~ qconsym
qconsym ~ consym | modid '.' consym

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

my $long_input = <<'EOS';
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

my $long_explicit_expected = Data::Dumper::Dumper( pruneNodes($long_explicit_ast) );

my $short_implicit_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
			    ], [] ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'a'
				      ] ] ] ], [ 'qop', [ 'qvarop', '*'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'b'
					] ] ] ] ] ] ] ] ],
			[ 'decl', [ 'funlhs',
			    [ 'var', 'f'
			    ], [ [ 'apat', [ 'var', 'x'
				] ] ],
			    ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', '(',
				      [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'x'
						] ] ] ],
					  [ 'qop', [ 'qvarop', '+'
					    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
						  ] ] ] ] ] ] ], ')'
				    ] ] ], [ 'qop', [ 'qvarop', '/'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
					] ] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_implicit_expected = Data::Dumper::Dumper( pruneNodes($short_implicit_ast) );

my $short_mixed_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
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
			    ], [ [ 'apat', [ 'var', 'x'
				] ] ],
			    ], [ 'rhs', '=',
			    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', '(',
				      [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'x'
						] ] ] ],
					  [ 'qop', [ 'qvarop', '+'
					    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'y'
						  ] ] ] ] ] ] ], ')'
				    ] ] ], [ 'qop', [ 'qvarop', '/'
				  ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'aexp', [ 'qvar', 'z'
					] ] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_mixed_expected = Data::Dumper::Dumper( pruneNodes($short_mixed_ast) );

my $short_alt_ast =
  [ 'module', [ 'body', [ 'topdecls', [ 'topdecl', [ 'decl', [ 'funlhs', [ 'var', 'main'
	      ], [] ], [ 'rhs', '=',
	      [ 'exp', [ 'infixexp', [ 'lexp', 'let',
		    [ [ 'decls', [ 'decl', [ 'funlhs', [ 'var', 'y'
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
					] ] ] ] ] ] ] ] ] ] ], 'in',
		    [ 'exp', [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
				] ] ], [ 'aexp', [ 'qvar', 'c'
			      ] ] ] ] ] ] ], [ 'qop', [ 'qvarop', '+'
		    ] ], [ 'infixexp', [ 'lexp', [ 'fexp', [ 'fexp', [ 'aexp', [ 'qvar', 'f'
			    ] ] ], [ 'aexp', [ 'qvar', 'd'
			  ] ] ] ] ] ] ] ] ] ] ] ] ];

my $short_alt_expected = Data::Dumper::Dumper( pruneNodes($short_alt_ast) );

my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
%main::GRAMMARS = (
    'ruby_x_body'  => ['topdecls'],
    'ruby_x_decls' => ['decls'],
    'ruby_x_alts'  => ['alts'],
);

for my $key ( keys %main::GRAMMARS ) {
    my $grammar_data = $main::GRAMMARS{$key};
    my ($start)      = @{$grammar_data};
    my $this_dsl     = ":start ::= $start\n";
    $this_dsl .= "inaccessible is ok by default\n";
    # say STDERR "Adding lines:\n$this_dsl";
    $this_dsl .= $dsl;
    my $this_grammar = Marpa::R2::Scanless::G->new( { source => \$this_dsl } );
    $grammar_data->[1] = $this_grammar;
    my $iKey = $key;
    $iKey =~ s/_x_/_i_/xms;
    $main::GRAMMARS{$iKey} = $grammar_data;

}

local $main::DEBUG = 0;

doTest( \$long_explicit, $long_explicit_expected );
doTest( \$short_implicit, $short_implicit_expected );
doTest( \$short_mixed, $short_mixed_expected );
doTest( \$short_alt, $short_alt_expected );
# $main::DEBUG = 1;
doTest( \$short_explicit, $short_implicit_expected );
$main::DEBUG = 0;

sub doTest {
    my ($inputRef, $expected_value ) = @_;
    my ($initialWS) = ${$inputRef} =~ m/ ^ ([\s]*) /xms;
    my $firstLexemeOffset = length $initialWS;

    my $currentIndent = -1;
    DETERMINE_INDENT: {
      my $initialChars = substr(${$inputRef}, $firstLexemeOffset, 7);
      if (substr($initialChars, 0, 1) eq '{') {
         last DETERMINE_INDENT;
      }
      if (substr($initialChars, 0, 6) =~ m/module\b/) {
         last DETERMINE_INDENT;
      }
      my $lastNL = rindex($initialWS, "\n");
      if (not defined $lastNL) {
          $currentIndent = $firstLexemeOffset;
         last DETERMINE_INDENT;
      }
      $currentIndent = $lastNL + 1;
    }

    my $indent_is_active = ($currentIndent >= 0 ? 1 : 0);
    say STDERR "Calling top level parser, indentation = $indent_is_active" if $main::DEBUG;
    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar   => $grammar,
            rejection => 'event',
	    event_is_active => { 'indent' => $indent_is_active },
            trace_terminals => ($main::DEBUG ? 99 : 0),
        }
    );

    my $value_ref;
    my $result = 'OK';
    my $eval_ok =
      eval { ( $value_ref, undef ) = getValue( $recce, $inputRef, $firstLexemeOffset, $currentIndent ); 1; };

    # say $recce->show_progress();
    if ( !$eval_ok ) {
        my $eval_error = $EVAL_ERROR;
      PARSE_EVAL_ERROR: {
            $result = "Error: $EVAL_ERROR";
            Test::More::diag($result);
        }
    }
    if ( $result ne 'OK' ) {
        Test::More::fail(qq{Result was "$result", not OK});
        Test::More::fail(qq{No value test, because result was not OK});
        return
    }
    Test::More::pass(qq{Result is OK});
    my $value = '[fail]';
    if ($value_ref) {
        $value = Data::Dumper::Dumper( pruneNodes($value_ref) );

        # say '===';
        # say $value;
        # say '===';
    }

    Test::Differences::eq_or_diff( $value, $expected_value, qq{Test of value} );
}

sub getValue {
    my ( $recce, $input, $offset, $currentIndent ) = @_;
    my $input_length = length ${$input};
    my $new_pos;
    my $this_pos;


  READ:
    for (
        $this_pos = $recce->read( $input, $offset ) ;
        $this_pos < $input_length ;
        $this_pos = $recce->resume($new_pos)
      )
    {
        my $events      = $recce->events();
        my $event_count = scalar @{$events};
        if ( $event_count < 0 ) {
            last READ;
        }
        if ( $event_count != 1 ) {
            divergence("One event expected, instead got $event_count");
        }

        my $event = $events->[0];
        my $name = $event->[0];
	# say STDERR "=== Event $name";
        if ( $name eq "indent" ) {

            my ( undef, $indent_start, $indent_end ) = @{$event};

            # If negative currentIndent, we are ignoring indentation
            if ( $currentIndent < 0 ) {
                $new_pos = $indent_end;
                next READ;
            }

            # indent length is end-start less one for the newline
            my $indent_length = $indent_end - $indent_start - 1;

            # say STDERR join '', 'Indent event @', $indent_start, q{-@},
              # $indent_end, ': "',
              # substr( ${$input}, $indent_start,
                # ( $indent_end - $indent_start ) ),
              # qq{"; current indent = $currentIndent};

            my $next_char = substr( ${$input}, $indent_end + 1, 1 );
            if ( not defined $next_char or $indent_length < $currentIndent ) {
		# say STDERR "Outdent!!!";
		# say STDERR join '', 'After outdent: "', substr(${$input}, $indent_end, 10), '"';
                $this_pos = $indent_end;
                last READ;
            }
            if ($next_char eq "\n") {
		# say STDERR "Empty line!!!";
                $new_pos = $indent_end + 1;
                next READ;
	    }
            # say STDERR "Statement continuation!!!"
              # if $indent_length > $currentIndent;
            # say STDERR "New Statement!!!";
            if ( $indent_length > $currentIndent ) {
                $new_pos = $indent_end;
                next READ;
            }
            # say STDERR "lexeme_read('ruby_semicolon', ...)";
            $recce->lexeme_read( 'ruby_semicolon', $indent_start,
                $indent_length, ';' )
              // divergence("lexeme_read('ruby_semicolon', ...) failed");
            $new_pos = $indent_end;
            next READ;
        }
        if ( $name eq "'rejected" ) {
            # say STDERR 'Rejected event; terminals expected: ',
              # @{ $recce->terminals_expected() };
            my @expected =
              grep { /^ruby_/xms; } @{ $recce->terminals_expected() };
            if ( not scalar @expected ) {
		say STDERR $recce->show_progress() if $main::DEBUG;
                divergence( "All tokens rejected, expecting ",
                    ( join " ", @expected ) );
            }
            if ( scalar @expected > 2 ) {
                divergence( "More than one ruby token expected; ",
                    ( join " ", @expected ) );
            }
            my $expected = pop @expected;
            my $subParseIndent   = -1;
	    DETERMINE_SUBINDENT: {
		my $prefix = substr($expected, 0, 7);
		last DETERMINE_SUBINDENT
		  if $prefix eq 'ruby_x_';
		if ($expected eq 'ruby_semicolon') {
		   last READ;
		}
		if ($prefix ne 'ruby_i_') {
		  say STDERR $recce->show_progress(0, -1) if $main::DEBUG;
		  divergence(qq{All tokens rejected, expecting "$expected"});
		}
		my $pos = $recce->pos();
		my $lastNL = rindex(${$input}, "\n", $pos);
		$subParseIndent = $pos - ($lastNL + 1);
	    }
            my ( $value_ref, $next_pos ) =
              subParse( $expected, $input, $this_pos, $subParseIndent );
            $recce->lexeme_read( $expected, $this_pos,
                $next_pos - $this_pos, $value_ref )
              // divergence("lexeme_read($expected, ...) failed");
            $new_pos = $next_pos;
            next READ;
        }
	divergence(qq{Unexpected event: "$name"});
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
	# say STDERR $recce->show_progress(0, -1);
	# say STDERR Data::Dumper::Dumper($value_ref);
        divergence( qq{input read, but there was no parse} );
    }

    return $value_ref, $this_pos;
}

sub subParse {
    my ( $target, $input, $offset, $currentIndent ) = @_;
    my $grammar_data = $main::GRAMMARS{$target};

    say STDERR "Calling subparser for $target" if $main::DEBUG;
    # say STDERR Data::Dumper::Dumper(\%main::GRAMMARS);
    divergence(qq{No grammar for target = "$target"}) if not $grammar_data;
    my ( undef, $subgrammar ) = @{$grammar_data};
    my $indent_is_active = ($currentIndent >= 0 ? 1 : 0);
    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar         => $subgrammar,
            rejection       => 'event',
	    event_is_active => { 'indent' => $indent_is_active },
            trace_terminals => ($main::DEBUG ? 99 : 0),
        }
    );
    my ( $value_ref, $pos ) = getValue( $recce, $input, $offset, $currentIndent );
    say STDERR "Returning from subparser for $target" if $main::DEBUG;
    return $value_ref, $pos;
}

sub pruneNodes {
    my ($v) = @_;

    state $nonStandard = {
        apats           => 1,
        apats1          => 1,
        duple_type_list => 1,
        exports         => 1,
        optExports      => 1,
        exp_tuple_list  => 1,
        flagged_atype   => 1,
        flagged_atypes  => 1,
        laidout_alts    => 1,
        laidout_decls   => 1,
        laidout_body    => 1,
        tuple_type_list => 1,
    };

    my $reftype = ref $v;
    return $v              if not $reftype;
    return pruneNodes($$v) if $reftype eq 'REF';
    return $v              if $reftype ne 'ARRAY';
    my @result     = ();
    my $first_elem = $v->[0];
    return [] if not defined $first_elem;

    if ( not defined $nonStandard->{$first_elem} ) {
        push @result, $first_elem;
    }
    for my $i ( 1 .. $#$v ) {
        push @result, pruneNodes( $v->[$i] );
    }
    return \@result;
}

