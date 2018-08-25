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

sub show_last_expression {
    my ($recce, $target) = @_;
    my ( $g1_start, $g1_length ) = $recce->last_completed($target);
    return qq{No "$target" was successfully parsed} if not defined $g1_start;
    my $last_expression = $recce->substring( $g1_start, $g1_length );
    return "Last expression successfully parsed was: $last_expression";
} 

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

laidout_body ::= (L0_leftCurly) ruby_x_body (L0_rightCurly)
	 | ruby_i_body
	 | L0_unicorn body L0_unicorn

optExports ::= L0_leftParen exports L0_rightParen
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

topdecl ::= resword_data simpletype L0_equal constrs
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

gendecl ::= vars L0_DoubleColon type
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
atype ::= L0_leftParen tuple_type_list L0_rightParen
atype ::= L0_leftSquare type L0_rightSquare
atype ::= L0_leftParen type L0_rightParen

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
funlhs ::= L0_leftParen funlhs L0_rightParen apats
apats  ::= apat*
apats1 ::= apat+

#  
# rhs	→	= exp [where decls]
# |	gdrhs [where decls]

rhs ::= L0_equal exp
rhs ::= L0_equal exp resword_where laidout_decls

# Here the logic is similar to <laidout_body>,
# see which above.
laidout_decls ::= (L0_leftCurly) ruby_x_decls (L0_rightCurly)
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
infixexp ::= L0_dash infixexp
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
lexp ::= resword_do laidout_stmts

# Here the logic is similar to <laidout_body>,
# see which above.
laidout_alts ::= (L0_leftCurly) ruby_x_alts (L0_rightCurly)
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
aexp ::= literal
aexp ::= L0_leftParen exp L0_rightParen
aexp ::= L0_leftParen exp_tuple_list L0_rightParen
aexp ::= L0_leftSquare exps L0_rightSquare
aexp ::= L0_leftSquare exp L0_pipe quals L0_rightSquare
quals ::= qual+ separator => L0_comma
aexp ::= gcon

exp_tuple_list ::= exp L0_comma exp
exp_tuple_list ::= exp_tuple_list L0_comma exp

exps ::= exp+ separator => L0_comma

#  
# qual	→	pat <- exp	    (generator)
# |	let decls	    (local declaration)
# |	exp	    (guard)
#  
# alts	→	alt1 ; … ; altn	    (n ≥ 1)

qual ::= pat L0_leftSingle exp
qual ::= resword_let decls
qual ::= exp

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

laidout_stmts ::= (L0_leftCurly) ruby_x_stmts (L0_rightCurly)
	 | ruby_i_stmts
	 | L0_unicorn stmts L0_unicorn
stmts ::= stmts_seq
stmts_seq ::= stmts_seq (virtual_semicolon) stmt
stmts_seq ::= stmt

stmt ::= exp
stmt ::= # empty

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
apat ::= var L0_atSign apat
apat ::= gcon
apat ::= literal
apat ::= L0_leftParen pat L0_rightParen
apat ::= L0_leftSquare pats1 L0_rightSquare

pats1 ::= pat+ separator => L0_comma

# fpat	→	qvar = pat
#  
# gcon	→	()
# |	[]
# |	(,{,})
# |	qcon

gcon ::= '()'
gcon ::= '[]'
gcon ::= L0_leftParen L0_commas L0_rightParen
gcon ::= qcon

# var	→	varid | ( varsym )	    (variable)

var ::= L0_reservedid_error
  | L0_varid
  | L0_leftParen L0_varsym L0_rightParen
  | L0_leftParen L0_ReservedOpError L0_rightParen

# qvar	→	qvarid | ( qvarsym )	    (qualified variable)

qvar ::= qvarid | L0_leftParen qvarsym L0_rightParen | L0_reservedid_error

# con	→	conid | ( consym )	    (constructor)

con ::= L0_conid
       | L0_leftParen L0_consym L0_rightParen
       | L0_leftParen L0_ReservedColonOpError L0_rightParen

# qcon	→	qconid | ( gconsym )	    (qualified constructor)

qcon ::= L0_qconid
       | L0_leftParen gconsym L0_rightParen

# varop	→	varsym | `  varid `	    (variable operator)

varop ::= L0_varsym
  | L0_ReservedOpError
  | L0_tick L0_varid L0_tick |
  L0_tick L0_reservedid_error L0_tick

# qvarop	→	qvarsym | `  qvarid `	    (qualified variable operator)

qvarop ::= qvarsym | L0_tick qvarid L0_tick | L0_tick L0_reservedid_error L0_tick

# conop	→	consym | `  conid `	    (constructor operator)
# qconop	→	gconsym | `  qconid `	    (qualified constructor operator)

qconop ::= gconsym | L0_tick L0_qconid L0_tick

# op	→	varop | conop	    (operator)
# qop	→	qvarop | qconop	    (qualified operator)

qop ::= qvarop | qconop

# gconsym	→	: | qconsym

gconsym ::= L0_colon | L0_qconsym

# ===== Part 3: Haskell lexical syntax =====

# This is from Section 10.2 of the 2010 Standard.

# Lexeme priorities follow this scheme:
#
# 2, the highest, is for lexemes intended to override "normal"
# ones.  For example, this is used to make reserved words and
# ops override normal variables and ops.
#
# 1 is used for "error lexemes".  For example, if a reserved
# word or op occurs where it should not, it is treated
# overriding normal variables and ops, but an event is generated
# which manually rejects it, causing a parse fail.
#
# 0 (the default) is used for everything else.

# A unicorn is a lexeme which cannot occur.
# Unicorns are used as dummy RHSs for Ruby Slippers
# tokens
:lexeme ~ L0_unicorn
L0_unicorn ~ unicorn
unicorn ~ [^\d\D]
ruby_i_body ~ unicorn
ruby_x_body ~ unicorn
ruby_i_stmts ~ unicorn
ruby_x_stmts ~ unicorn
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

:lexeme ~ L0_leftParen
L0_leftParen ~ '('
:lexeme ~ L0_rightParen
L0_rightParen ~ ')'
:lexeme ~ L0_leftSquare
L0_leftSquare ~ '['
:lexeme ~ L0_rightSquare
L0_rightSquare ~ ']'
:lexeme ~ L0_leftCurly
L0_leftCurly ~ '{'
:lexeme ~ L0_rightCurly
L0_rightCurly ~ '}'
:lexeme ~ L0_tick
L0_tick ~ '`'

:lexeme ~ L0_commas
:lexeme ~ L0_comma
L0_commas ~ commas
L0_comma ~ comma
commas ~ comma*
comma ~ [,]

L0_semicolon ~ semicolon
ruby_semicolon ~ unicorn
semicolon ~ [;]

literal ~ integer

:discard ~ L0_horizontalWhitechars
L0_horizontalWhitechars ~ horizontalWhitechars
horizontalWhitechars ~ horizontalWhitechar*
horizontalWhitechar ~ [ ]

verticalWhitechar ~ [\n]

whitechars ~ whitechar*
whitechar ~ horizontalWhitechar
whitechar ~ verticalWhitechar
whitechar ~ dashComment

dashComment ~ '--' nonNewlines
nonNewlines ~ nonNewline*
nonNewline ~ [^\n]

# Right now this will fail -- tabs are a
# nuisance and I am not in a hurry to implement
# them
:discard ~ tab event => tab
tab ~ [\t]

# <commentline> will be longer than
# any <indent>, so that Marpa's own lexer
# can "eat" these lines.  This is cleaner
# and easier than dealing with these in the
# event handler.

# Here we define an "event" for <indent>.
# The event is initially set to off.
:discard ~ indent event => indent=off
indent ~ whitechars newline horizontalWhitechars

# space	→	a space
# tab	→	a horizontal tab
# uniWhite	→	any Unicode character defined as whitespace
#  
# comment	→	dashes [ any⟨symbol⟩ {any} ] newline


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
:lexeme ~ L0_dash
L0_dash ~ dash
dash ~ '-'
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

:lexeme ~ L0_reservedid_error event => reservedid pause=>before priority => 1
L0_reservedid_error ~ reservedid
reservedid ~ 'case' | 'class' | 'data' | 'default' | 'deriving' | 'do' | 'else'
|	'foreign' | 'if' | 'import' | 'in' | 'infix' | 'infixl'
|	'infixr' | 'instance' | 'let' | 'module' | 'newtype' | 'of'
|	'then' | 'type' | 'where' | '_'

# Revered word lexemes are set to priority 2.  Priorities allow
# one lexeme to "outprioritize" others.  They only
# apply if both lexemes start and end at the same location.
# Default priority is zero, so lexemes will outprioritize
# most lexemes, including normal variables.
:lexeme ~ resword_case priority => 2
resword_case ~ 'case'
# :lexeme ~ resword_class priority => 2
# resword_class ~ 'class'
:lexeme ~ resword_data priority => 2
resword_data ~ 'data'
# :lexeme ~ resword_default priority => 2
# resword_default ~ 'default'
# :lexeme ~ resword_deriving priority => 2
# resword_deriving ~ 'deriving'
:lexeme ~ resword_do priority => 2
resword_do ~ 'do'
# :lexeme ~ resword_else priority => 2
# resword_else ~ 'else'
# :lexeme ~ resword_foreign priority => 2
# resword_foreign ~ 'foreign'
# :lexeme ~ resword_if priority => 2
# resword_if ~ 'if'
# :lexeme ~ resword_import priority => 2
# resword_import ~ 'import'
:lexeme ~ resword_in priority => 2
resword_in ~ 'in'
# :lexeme ~ resword_infix priority => 2
# resword_infix ~ 'infix'
# :lexeme ~ resword_infixl priority => 2
# resword_infixl ~ 'infixl'
# :lexeme ~ resword_infixr priority => 2
# resword_infixr ~ 'infixr'
# :lexeme ~ resword_instance priority => 2
# resword_instance ~ 'instance'
:lexeme ~ resword_let priority => 2
resword_let ~ 'let'
:lexeme ~ resword_module priority => 2
resword_module ~ 'module'
# :lexeme ~ resword_newtype priority => 2
# resword_newtype ~ 'newtype'
:lexeme ~ resword_of priority => 2
resword_of ~ 'of'
# :lexeme ~ resword_then priority => 2
# resword_then ~ 'then'
# :lexeme ~ resword_type priority => 2
# resword_type ~ 'type'
:lexeme ~ resword_where priority => 2
resword_where ~ 'where'
# :lexeme ~ resword_underscore priority => 2
# resword_underscore ~ '_'

# varsym	→	( symbol⟨:⟩ {symbol} )⟨reservedop | dashes⟩

# Handling <dashes>, since they start a comment, is implemented
# in the comment processing.  Comments always include a newline,
# while <varsym>'s never do, so comments will always be preferred
# by the LATM lexing discipline.
# this is a problem if they are just before a newline.

:lexeme ~ L0_varsym
L0_varsym ~ varsym
varsym ~ nonColonSymbol symbols
symbols ~ symbol*

# consym	→	( : {symbol})⟨reservedop⟩

:lexeme ~ L0_consym
L0_consym ~ consym
consym ~ colon symbols

# reservedop	→	.. | : | :: | = | \ | | | <- | -> |  @ | ~ | =>

:lexeme ~ L0_ReservedColonOpError event => reservedColonOp pause=>before priority => 1
L0_ReservedColonOpError ~ reservedColonOp
reservedColonOp ~ ':' | '::'

:lexeme ~ L0_DoubleColon priority => 2
L0_DoubleColon ~ '::'

:lexeme ~ L0_ReservedOpError event => reservedop pause=>before priority => 1
L0_ReservedOpError ~ reservedop
reservedop ~ '..' | '=' | '\' | '|' | '<-' | '->' | '@' | '~' | '=>'
    | reservedColonOp

:lexeme ~ L0_equal priority => 2
L0_equal ~ '='
:lexeme ~ L0_pipe priority => 2
L0_pipe ~ '|'
:lexeme ~ L0_leftSingle priority => 2
L0_leftSingle ~ '<-'
:lexeme ~ L0_atSign priority => 2
L0_atSign ~ '<-'

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

decimal ~ digit+

# octal	→	octit{octit}
# hexadecimal	→	hexit{hexit}
#  
# integer	→	decimal
# |	0o octal | 0O octal
# |	0x hexadecimal | 0X hexadecimal

integer ~ decimal

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
    'ruby_x_stmts'  => ['stmts'],
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
      eval { ( $value_ref, undef ) = getValue( $recce, 'module', $inputRef, $firstLexemeOffset, $currentIndent ); 1; };

    if ($main::TRACE_ES) {
      my $thick_recce = $recce->thick_g1_recce();
      say STDERR qq{Returning from top level parser};
      my $latest_es = $thick_recce->latest_earley_set();
      say STDERR "latest ES = ", $latest_es;
      for my $es (0 .. $latest_es) {
	say STDERR "ES $es = ", $thick_recce->earley_set_size($es);
	say STDERR $thick_recce->show_progress($es);
      }
    }
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
    my ( $recce, $target, $input, $offset, $currentIndent ) = @_;
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

        if ( $name eq 'reservedid' ) {
	    say STDERR 'Reserved Id event' if $main::DEBUG;
	    say STDERR show_last_expression($recce, 'decls') if $main::DEBUG;
	    last READ;
	}
        if ( $name eq 'reservedop' ) {
	    say STDERR 'Reserved Op event' if $main::DEBUG;
	    say STDERR show_last_expression($recce, 'decls') if $main::DEBUG;
	    last READ;
	}

        if ( $name eq 'indent' ) {

            my ( undef, $indent_start, $indent_end ) = @{$event};
	    say STDERR 'Indent event @', $indent_start, '-',
	       $indent_end, '; current = ', $currentIndent
	       if $main::DEBUG;

	    my $lastNL = rindex(${$input}, "\n", $indent_end);

	    my $indent_length = ($indent_end - $lastNL) - 1;
	    $indent_length = 0 if $indent_length < 0;

	    say STDERR 'Indent length = ', $indent_length
	       if $main::DEBUG;

	    # On outdent, we end the read loop.  An EOF is treated as
	    # an outdent.
            my $next_char = substr( ${$input}, $indent_end + 1, 1 );
            if ( not defined $next_char or $indent_length < $currentIndent ) {
		say STDERR 'Indent is outdent'
		   if $main::DEBUG;
                $this_pos = $lastNL;
                last READ;
            }

	    # Skip empty lines -- their whitespace does not count as identation.
            if ($next_char eq "\n") {
		# An empty line.
		# Comments are dealt with separately, taking advantage of the
		# fact they they must be longer and therefore preferred by
		# the lexer.
		say STDERR 'Indent is an empty line'
		   if $main::DEBUG;
                $resume_pos = $indent_end;
                next READ;
	    }

	    # Indentation deeper than the current indent means the current
	    # syntactic item is being continued.  Just resume the read.
            if ( $indent_length > $currentIndent ) {
		# Statement continuation
		say STDERR 'Indent is item continuation: "',
		      substr(${$input}, $indent_end, 10),
		      '"'
		   if $main::DEBUG;
                $resume_pos = $indent_end;
                next READ;
            }

	    say STDERR 'Indent is new item : "',
		  substr(${$input}, $indent_end, 10),
		  '"'
	       if $main::DEBUG;

	    # If we are here, indent is at the current indent level.
	    # This means we are starting a new syntactic item.  The
	    # parser will be expecting a Ruby Slippers semicolon,
	    # and we provide it, then resume reading.
	    {
	      my $result = $recce->lexeme_read( 'ruby_semicolon', $indent_start,
		  $indent_length, ';' );
	      say STDERR "lexeme-read('ruby_semicolon',...) returned ",
		  Data::Dumper::Dumper(\$result)
		  if $main::DEBUG;

	    }
            $resume_pos = $indent_end;
            next READ;
        }

	# Items subject to layout are represented by Ruby Slippers tokens,
	# which are not recognized by the internal lexer.  Therefore they
	# generate rejection events.

	# Errors in the source can also generate "rejected" events.  To
	# become ready for production, this module would need to add better
	# logic for debugging and tracing in those cases.
        if ( $name eq "'rejected" ) {
            my @expected =
              grep { /^ruby_/xms; } @{ $recce->terminals_expected() };

	    # If no Ruby Slippers tokens are expected, it probably
	    # indicates a syntax error in the Haskell source.
            if ( not scalar @expected ) {
                divergence( "All tokens rejected, expecting ",
                    ( join " ", @expected ) );
            }

	    # More than one Ruby Slippers token expected is a
	    # circumstance which should not occur.
            if ( scalar @expected > 2 ) {
                divergence( "More than one ruby token expected; ",
                    ( join " ", @expected ) );
            }

	    # If we rejected all tokens, and we expect a Ruby
	    # Slippers semicolon, it indicates we have recognized
	    # the target of this combinator.  We therefore terminate
	    # the read.
            my $expected = pop @expected;
	    if ($expected eq 'ruby_semicolon') {
	       say STDERR "Ending READ loop expecting ruby_semicolon"
	           if $main::DEBUG;
	       last READ;
	    }

	    # If here, we need to start a new sub-combinator.  These
	    # can be nested arbitrarily deep.  Calculate
	    # new current indent.
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

	    # Start the new combinator.
            my ( $value_ref, $next_pos ) =
              subParse( $expected, $input, $this_pos, $subParseIndent );

	    # The child combinator finished -- read its result into the current
	    # combinator as a lexeme.
            $recce->lexeme_read( $expected, $this_pos,
                $next_pos - $this_pos, $value_ref )
              // divergence("lexeme_read($expected, ...) failed");

	    # Set up to resume this combinator where the child combinator left off.
            $resume_pos = $next_pos;

	    # Resume reading.
            next READ;
        }

	divergence(qq{Unexpected event: "$name"});
    }

    say STDERR "Left main READ loop" if $main::DEBUG;

    # Return value and new offset

    my $value_ref = $recce->value();
    if ( !$value_ref ) {
	say STDERR $recce->show_progress() if $main::DEBUG;
        divergence( qq{input read, but there was no parse} );
    }

    return $value_ref, $this_pos;
}

sub subParse {
    my ( $target, $input, $offset, $currentIndent ) = @_;
    say STDERR qq{Starting combinator for "$target" at $currentIndent}
        if $main::TRACE_ES;
    say STDERR qq{Starting combinator for "$target" at $currentIndent}
        if $main::DEBUG;
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
    my ( $value_ref, $pos ) = getValue( $recce, $target, $input, $offset, $currentIndent );
    say STDERR qq{Returning from combinator for "$target" at $currentIndent}
        if $main::DEBUG;

    if ($main::TRACE_ES) {
      my $thick_recce = $recce->thick_g1_recce();
      say STDERR qq{Returning from combinator for "$target" at $currentIndent};
      my $latest_es = $thick_recce->latest_earley_set();
      say STDERR "latest ES = ", $latest_es;
      for my $es (0 .. $latest_es) {
	say STDERR "ES $es = ", $thick_recce->earley_set_size($es);
      }
      say STDERR qq{Returning from combinator for "$target" at $currentIndent};
    }

    return $value_ref, $pos;
}

# This utility right now is primarily for testing.  It takes an
# AST and returns one whose nodes more closely match the standard.
# Right now, this makes it easy for test cases, but perhaps this
# could also be the start of a compile/interpretation phase.

# Takes one argument and returns a ref to an array of acceptable
# nodes.  The array may be empty.  All scalars are acceptable
# leaf nodes.  Acceptable interior nodes have length at least 1
# and contain a Haskell Standard symbol name, followed by zero or
# more acceptable nodes.
sub pruneNodes {
    my ($v) = @_;

    state $deleteIfEmpty = {
        topdecl => 1,
        decl => 1,
    };

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
        laidout_stmts      => 1,
        stmts_seq      => 1,
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
    my $element_count = scalar @source;
    return [] if $element_count <= 0; # must have at least one element
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
    if (defined $deleteIfEmpty->{$name} and $element_count == 1) {
      return [];
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
