#!/usr/bin/perl

# TO READERS OF THIS CODE:

# This is intended as an example of a method for doing
# combinator parsing with the Earley/Leo/Marpa algorithm,
# which is not tied to Perl.  As such, it might attract readers
# not happy with having to read Perl.  To them,
# my apologies, and these notes, which I cannot
# eliminate the pain, but which I hope will make
# it more brief and easier to bear.

# The code is in 4 parts
#
# 1.) A Perl-oriented preamble, which the Perl-adverse
# can skip.
#
# 2.) The Haskell context-free syntax, translated from the 2010
# standard
#
# 3.) The Haskell lexical syntax, also translated from the 2010
# standard
#
# 4.) Wrappers and event handlers, in Perl.
#
# The comments interspersed in the code are not self-sufficient.
# They assume that the reader has read a description of the overall
# logic of this parser, for example the one in my blog post.

# ===== Part 1: Perl preamble =====

use 5.010;
use strict;
use warnings;

use Marpa::R2 4.000;

package MarpaX::R2::Haskell;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Deepcopy = 1;

use English qw( -no_match_vars );

sub divergence {
    die join '', 'Unrecoverable internal error: ', @_;
}

# ===== Part 2: Haskell context-free syntax =====

# This is translated into Marpa's DSL from the Haskell 2010 standard.
# The original standard is included as commments.  As well as tying
# the translation to the original, inclusion of the original shows
# the elements of syntax omitted (so far?) from the translated subset.
#
# The copy-and-paste from the standard removed the typography
# needed to distinguish syntax from meta-syntax -- readers who 
# need clarification should refer to the original:
# https://www.haskell.org/onlinereport/haskell2010/haskellch10.html#x17-18000010.5
#
# The translation into Marpa preserves the symbol names of the standard.
# The translation often required new rules, and the introduction of new symbols.
# One of the handlers, pruneNodes(), removes the symbol names introduced for
# the translation, leaving only symbol names from the Haskell 2010 standard in
# the AST.
# 
# Marpa divides symbols into
#
# * those for the context-free grammar (G1 in Marpa terms), whose rules
#   are indicated by the '::=' operator; and
# * those for the lexical grammar (L0 in Marpa terms), whose rules are
#   indicated by the '~' operator.
#
# In Marpa, the lexical grammar(L0)  is also allowed to be fully contest-free.
# For implemenation, Marpa requires those symbols which are the "boundary"
# between G1 and L0 to be specified clearly.  Usually this is done implicitly --
# a symbol which is on a RHS but not a LHS in G1, and which is on a LHS but not
# a RHS in L0, is considered a G1/L0 boundary symbol, or "lexeme".
#
# The Haskell 2010 grammar is, of course, not a native Marpa grammar, so it was
# often necessary to specify explicitly what the lexeme are.  This is done
# with the ":lexeme" declarations.  Where a symbol needed to be introduced
# to allow a clean boundary, the new symbol has the prefix "L0_".

my $dsl = <<'END_OF_DSL';

# This preamble establishes the lexing discipline -- LATM
# or Longest Acceptable Token Match, where "acceptable"
# means that tokens which the grammar would reject do not
# count when calculating which is "longest".  (Unlike traditional
# parsers, Marpa is smart enough to tell the lexer which tokens
# are acceptable.
lexeme default = latm => 1

# This tells Marpa to construct an AST whose nodes consist of the
# symbol name, followed a by a list of the child values.
:default ::= action => [name,values]

# The next comment is an extract from the standard -- the first of
# many.

# module	→	module modid [exports] where body 
# |	body

# Marpa (of course) cannot recognize the typographical distinctions
# that the standard's grammar uses, so reserved words are indicated
# explicitly.  For example, <resword_module> is the symbol for the
# reserved word "module".

module ::= resword_module L0_modid optExports resword_where laidout_body
         | body

# Here is one of the rules which are part of the Ruby Slippers logic.
# (As a reminder, Ruby Slippers symbols are *not* found in the 
# the actual input, but are present in the Marpa grammar as signal
# to supply the Ruby Slippers symbol using external logic.
#
# The original symbol in the 2010 Standard is <body>.  Here three
# new symbols are introduced.  <ruby_x_body> is the Ruby Slippers symbol
# for an explicitly laid-out body.  <ruby_i_body> is the Ruby Slippers
# symbol for an implicitly laid-out body.  <laidout_body> is a LHS for a
# laid-out body which may be either implicit or explicit.
# 
# One alternative uses the original 2010 standard symbol, <body>.
# This alternative is "fake" -- the <L0_unicorn> symbol will never
# be found in any input.  The fake alternative exists to fool Marpa into thinking
# <body> and its child symbols are accessible.  This is not necessary --
# Marpa can turn off warnings for inaccessible symbols, but it was
# helpful for grammar debugging.  Inclusion of <body> and its child
# symbols increases the grammar size, but the start-up cost of increasing the
# size of a Marpa grammar is reasonable, and the runtime cost of the
# larger grammar is negligible.

laidout_body ::= ('{') ruby_x_body ('}')
	 | ruby_i_body
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

# The 2010 standard is ambiguous -- an empty string can
# be either a zero-length sequence of <topdecls>, or
# a <topdecls> sequence of length one consisting of
# an empty <gendecl>.  Marpa can handle ambiguity but
# this one has no semantic relevance and is a pointless
# nuisance.  I resolve it by requiring a <topdecls>
# sequence to have a minimm length of one.

# Marpa (to prevent confusions like that of the 2010
# Standard) bans nullable RHS symbols in its sequence rules,
# so we have to write this one out in BNF.
# <topdecls_seq> is an introduced symbol which will
# be eliminated from the AST.

# Note the parentheses around <virtual_semicolon>.  They
# indicate that it is to hid from the semantics -- in this case,
# this avoids clutter in the AST.

topdecls ::= topdecls_seq
topdecls_seq ::= topdecls_seq (virtual_semicolon) topdecl
topdecls_seq ::= topdecl

# Semicolons may be provided by the Ruby Slippers, or
# they may be real.
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
# <decl>
decls ::= decls_seq
decls_seq ::= decls_seq (virtual_semicolon) decl
decls_seq ::= decl

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
gendecl ::= # empty

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

# Here the logic is similar to <laidout_body>,
# see which above.
laidout_decls ::= ('{') ruby_x_decls ('}')
	 | ruby_i_decls
	 | L0_unicorn decls L0_unicorn

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

# Here the logic is similar to <laidout_body>,
# see which above.
laidout_alts ::= ('{') ruby_x_alts ('}')
	 | ruby_i_alts
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
alts ::= alts (virtual_semicolon) alt

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

# ===== Part 3: Haskell lexical syntax =====

# This is from Section 10.2 of the 2010 Standard.

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

# <commentline> will be longer than
# any <indent>, so that Marpa's own lexer
# can "eat" these lines.  This is cleaner
# and easier than dealing with these in the
# event handler.
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

# ===== Part 4: Wrappers and handlers =====

# The following logic pre-generates all the grammars we
# will need, both for the top level and the combinators.

my $topGrammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );

%main::GRAMMARS = (
    'ruby_x_body'  => ['body'],
    'ruby_x_decls' => ['decls'],
    'ruby_x_alts'  => ['alts'],
);

# Rather than writing 6 grammars for the combinators, we can
# (mostly) reuse the top-level grammar.  Marpa's ":start"
# pseudo-symbol allows us to override the default start
# symbol.  Changing the start symbol makes a long of symbols
# inaccessible, but the "inaccessible is ok by default"
# statement turns of the warnings for these.

for my $key ( keys %main::GRAMMARS ) {
    my $grammar_data = $main::GRAMMARS{$key};
    my ($start)      = @{$grammar_data};
    my $this_dsl     = ":start ::= $start\n";
    $this_dsl .= "inaccessible is ok by default\n";
    $this_dsl .= $dsl;
    my $this_grammar = Marpa::R2::Scanless::G->new( { source => \$this_dsl } );
    $grammar_data->[1] = $this_grammar;
    my $iKey = $key;
    $iKey =~ s/_x_/_i_/xms;
    $main::GRAMMARS{$iKey} = $grammar_data;

}

local $main::DEBUG = 0;

# This is the top level parse routine.

sub parse {
    my ($inputRef) = @_;
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

    # $currentIndent is the column number of the indent, or
    # -1 is explicit layout is being used.  Note column indents here
    # are zero-based, as opposed to the 2010 standard, whose
    # description uses 1-based column indents.

    # Create the recognizer instance.
    # The 'indent' event is turned on or off, depending on whether
    # explicit or implicit layout is in use.

    my $indent_is_active = ($currentIndent >= 0 ? 1 : 0);
    say STDERR "Calling top level parser, indentation = $indent_is_active" if $main::DEBUG;
    my $recce = Marpa::R2::Scanless::R->new(
        {
            grammar   => $topGrammar,
            rejection => 'event',
	    event_is_active => { 'indent' => $indent_is_active },
            trace_terminals => ($main::DEBUG ? 99 : 0),
        }
    );

    # Get the parse value.

    my $value_ref;
    my $result = 'OK';
    my $eval_ok =
      eval { ( $value_ref, undef ) = getValue( $recce, $inputRef, $firstLexemeOffset, $currentIndent ); 1; };

    # Return result and parse value

    if ( !$eval_ok ) {
        my $eval_error = $EVAL_ERROR;
	$result = "Error: $EVAL_ERROR";
    }
    return $result, $value_ref;
}

# This handler assumes a recognizer has been created.  Given
# an input, an offset into that input, and a current indent
# level, it reads using that recognizer.  The return values
# are the parse value and a new offset in the input.
# Errors are thrown.

sub getValue {
    my ( $recce, $input, $offset, $currentIndent ) = @_;
    my $input_length = length ${$input};
    my $resume_pos;
    my $this_pos;

  # The main read loop.  Read starting at $offset.
  # If interrupted execute the handler logic,
  # and, possibly, resume.

  READ:
    for (
        $this_pos = $recce->read( $input, $offset ) ;
        $this_pos < $input_length ;
        $this_pos = $recce->resume($resume_pos)
      )
    {
	# Only one event at a time is expected -- more
	# than one is an error.  No event means parsing
	# is exhausted.

        my $events      = $recce->events();
        my $event_count = scalar @{$events};
        if ( $event_count < 0 ) {
            last READ;
        }
        if ( $event_count != 1 ) {
            divergence("One event expected, instead got $event_count");
        }

	# Find the event name

        my $event = $events->[0];
        my $name = $event->[0];

	# An "indent" event occurs whenever indentation is recognized.
	# The Marpa parser discards indentation, but it also can generate
	# an event.  "indent" events are only turned on if we are using
	# implicit layout.

        if ( $name eq 'indent' ) {

            my ( undef, $indent_start, $indent_end ) = @{$event};
	    say STDERR 'Indent event @', $indent_start, '-',
	       $indent_end if $main::DEBUG;

            # indent length is end-start less one for the newline
            my $indent_length = $indent_end - $indent_start - 1;

            my $next_char = substr( ${$input}, $indent_end + 1, 1 );
            if ( not defined $next_char or $indent_length < $currentIndent ) {
		# An outdent
		my $lastNL = rindex(${$input}, "\n", $indent_end);
		$lastNL = 0 if $lastNL < 0; # this probably never occurs
                $this_pos = $lastNL;
                last READ;
            }
            if ($next_char eq "\n") {
		# An empty line.
		# Comments are dealt with separately, taking advantage of the
		# fact they they must be longer and therefore preferred by
		# the lexer.
                $resume_pos = $indent_end + 1;
                next READ;
	    }

            if ( $indent_length > $currentIndent ) {
		# Statement continuation
                $resume_pos = $indent_end;
                next READ;
            }
            $recce->lexeme_read( 'ruby_semicolon', $indent_start,
                $indent_length, ';' )
              // divergence("lexeme_read('ruby_semicolon', ...) failed");
            $resume_pos = $indent_end;
            next READ;
        }
        if ( $name eq "'rejected" ) {
            my @expected =
              grep { /^ruby_/xms; } @{ $recce->terminals_expected() };
            if ( not scalar @expected ) {
                divergence( "All tokens rejected, expecting ",
                    ( join " ", @expected ) );
            }
            if ( scalar @expected > 2 ) {
                divergence( "More than one ruby token expected; ",
                    ( join " ", @expected ) );
            }
            my $expected = pop @expected;
	    if ($expected eq 'ruby_semicolon') {
	       last READ;
	    }
            my $subParseIndent   = -1;
	    DETERMINE_SUBINDENT: {
		my $prefix = substr($expected, 0, 7);
		last DETERMINE_SUBINDENT
		  if $prefix eq 'ruby_x_';
		if ($prefix ne 'ruby_i_') {
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
            $resume_pos = $next_pos;
            next READ;
        }
	divergence(qq{Unexpected event: "$name"});
    }

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
        divergence( qq{input read, but there was no parse} );
    }

    return $value_ref, $this_pos;
}

sub subParse {
    my ( $target, $input, $offset, $currentIndent ) = @_;
    my $grammar_data = $main::GRAMMARS{$target};

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
    return $value_ref, $pos;
}

# Takes one argument and returns a ref to an array of acceptable
# nodes.  The array may be empty.  All scalars are acceptable
# leaf nodes.  Acceptable interior nodes have length at least 1
# and contain a Haskell Standard symbol name, followed by zero or
# more acceptable nodes.
sub pruneNodes {
    my ($v) = @_;

    state $nonStandard = {
        apats             => 1,
        apats1            => 1,
        decls_seq         => 1,
        duple_type_list   => 1,
        exports           => 1,
        optExports        => 1,
        exp_tuple_list    => 1,
        flagged_atype     => 1,
        flagged_atypes    => 1,
        laidout_alts      => 1,
        laidout_decls     => 1,
        laidout_body      => 1,
        topdecls_seq      => 1,
        tuple_type_list   => 1,
        virtual_semicolon => 1,
    };

    return [] if not defined $v;
    my $reftype = ref $v;
    return [$v] if not $reftype; # An acceptable leaf node
    return pruneNodes($$v) if $reftype eq 'REF';
    divergence("Tree node has reftype $reftype") if $reftype ne 'ARRAY';
    my @source = grep { defined } @{$v};
    return [] if not scalar @source; # must have at least one element
    my $name = shift @source;
    my $nameReftype = ref $name;
    # divergence("Tree node name has reftype $nameReftype") if $nameReftype;
    if ($nameReftype) {
      my @result = ();
      ELEMENT:for my $element ($name, @source) {
	if (ref $element eq 'ARRAY') {
	  push @result, grep { defined }
		  map { @{$_}; }
		  map { pruneNodes($_); }
		  @{$element}
		;
	  next ELEMENT;
	}
	push @result, $_;
      }
      return [@result];
    }
    if (defined $nonStandard->{$name}) {
      # Not an acceptable branch node, but (hopefully)
      # its children are acceptable
      return [ grep { defined }
	      map { @{$_}; }
	      map { pruneNodes($_); }
	      @source
	    ];
    }

    # An acceptable branch node
    my @result = ($name);
    push @result, grep { defined }
	    map { @{$_}; }
	    map { pruneNodes($_); }
	    @source;
    return [\@result];
}

1;
