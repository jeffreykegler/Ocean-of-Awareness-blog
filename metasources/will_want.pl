#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use autodie;

sub usage {
	my ($message) = @_;
	die $message, "\nusage: $PROGRAM_NAME";
}

my $fn_number = 0;
my @fn_lines = ();
my @lines = ();

LINE: while ( my $line = <DATA> ) {
    chomp $line;
    if ( $line =~ /<footnote>/ ) {
        do_footnote($line);
	next LINE;
    }
    push @lines, $line;
}

my $output = join "\n", @lines;
my $footnotes = join "\n", '<h2>Footnotes</h2>', @fn_lines;
$output =~ s[<comment>FOOTNOTES HERE</comment>][$footnotes];

say $output;

sub do_footnote {
    my ($line) = @_;
    $fn_number++;
    my $fn_ref = join '-', 'footnote', $fn_number, 'ref';
    my $fn_href = join '-', 'footnote', $fn_number;
    my $footnoted_line = $line;
    $footnoted_line =~ s/<footnote>.*$//;
    $footnoted_line .= qq{<a id="$fn_ref" href="#$fn_href">[$fn_number]</a>};
    push @fn_lines, qq{<p id="$fn_href">$fn_number.};
    $line =~ s/^.*<footnote>//;
    my $inside_footnote = $line;
    $inside_footnote =~ s/^.*<footnote>//;
    push @fn_lines, $inside_footnote if $inside_footnote =~ m/\S/;
    my $post_footnote = '';
  FN_LINE: while ( my $fn_line = <DATA> ) {
        chomp $fn_line;
        if ( $fn_line =~ m[<\/footnote>] ) {
	    $post_footnote = $fn_line;
	    $post_footnote =~ s[^.*<\/footnote>][];
	    $fn_line =~ s[</footnote>.*$][];
	    push @fn_lines, $fn_line if $fn_line =~ m/\S/;
	    push @fn_lines, qq{ <a href="#$fn_ref">&#8617;</a></p>};
	    last FN_LINE;
        }
	push @fn_lines, $fn_line;
    }
    $footnoted_line .= $post_footnote;
    push @lines, $footnoted_line if $footnoted_line =~ m/\S/;
}

__DATA__
The Five Virtues of Parsers
<html>
  <head>
  </head>
  <body>
    <p>
      <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
      In a previous post<footnote>
      Much of the material in this post is drawn from my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
      V3 of my "Parsing: A Timeline"</a>.
      </footnote>, I did a careful examination of the
      history of attempts to produce the ideal parser.
      In this one, I will look at the question in reverse --
      what makes the users of a parser
      happy or unhappy with it?
      That is, once a parser is discovered,
      what makes it successful?
      And once a parser is successful,
      what causes users to want more?
    </p>
    <h2>The first major virtue: fast</h2>
    <p>
      By one accounting,
      the first systematic attempt at parsing
      was via regular expressions.<footnote>
      Strictly speaking,
      regular expressions are recognizers,
      not parsers
      (see "Term: parser" and
      "Term: recognzier" in
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">).
      This is because, in their pure form, regular expressions
      simply determine if the input is a match --
      they do not determine its structure.
      Nonetheless, regex engines in practical use
      often extend regular expressions,
      for example, by adding captures.
      At the low end, regexes often compete with parsers
      and why that is the case is very relevant to my
      concerns in this post.</footnote>
      Regular expressions are still very much with us,
      so they obviously must demonstrate at least <b>some</b>
      of the virtues that make a parser popular.
    </p>
    <p>
      The most superficial of these is that
      a parser must be "fast enough"
      to please its users.
      A rigorous understanding of what "fast enough" means
      was slow to emerge,
      but it is now clear that, except in restricted uses,
      a parser must be linear or quasi-linear.<footnote>
      For definitions of "linear" and "quasi-linear",
      see the 'Term: "linear"' section of
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
      V3 of my "Parsing: A Timeline"</a>.
      </footnote>
    </p>
    <h2>The second major virtue: predictable</h2>
    <p>
    Less obvious is what I will call "predictability":
    It must be possible for a programmer,
    with reasonable effort,
    to know if her grammar
    will be parsed by the parser.
    In this respect, regular expressions can be called
    perfect --
    there's a handy notation for them.
    Anything in that notation is a regular expression,
    and will be parsed in linear time by your regular
    expression engine --
    you never need to desk-check.
    </p>
    <h2>The first minor virtue: declaration-driven</h2>
    <p>Since there is a exact notation
    for regular expression, it has the first minor virtue:
    it is declaration-driven.
    If a parser can automatically be generated from a compact
    notation, the parsing method is declaration-driven.
    </p>
    <p>
    I call virtues minor
    if they are important in the eyes of the users,
    but of less importance than the major virtues.
    That "declaration-driven" is a minor virtue is clear
    from the history of parsing practice.
    </p>
    <h2>The third major virtue: power</h2>
    <p>Regular expressions, however,
    were not the end of the parsing story.
    If a programmer has a grammar she considers practical,
    she wants her parser to parse it.
    Here regular expressions often fail -- a lot of practical
    grammar are regular expressions, but many others are not.
    For regular expressions,
    one of the fails is ironic --
    the notation for regular expressions is recursive,
    but regular expressions cannot deal with recursion.
    </p>
    <p>
    Grabs for power predate the parsing literature,
    which begins with Irons 1961.
    In terms of power,
    Irons parser is "general",
    meaning that it can parse what are called
    the "context-free grammars".
    </p>
    <p>
    The context-free grammars are exactly those which can
    be written in BNF.
    This means that Irons parser had the same kind of predictability
    that regular expressions had -- it could parse every grammar
    written in its grammar notation.
    Again, there was no need to desk check,
    but this time the class of grammars that could be parsed was
    much, much larger.
    </p>
    <h2>The fourth major virtue: reliability</h2>
    <p>
    The Irons 1961 algorithm was perfectly predictable
    it was predictably powerful.
    And it could be fast.
    Iron 1961 was not predictably fast.
    In the general case,
    Irons 1961 used backtracking
    to achieve its power,
    so it would go exponential for many useful grammars.
    Irons 1961 could not be relied on to be fast.
    </p>
    <p>
    Irons 1961 gave way to recursive descent.
    Recursive descent had many disadvantages compared to Irons 1961,
    but it was very fast,
    it was easy to customize.
    With customization.
    recursive descent was 
    reliably fast for arithmetic expressions,
    which made it an improvement over Irons.
    </p>
    <h2>The second minor virtue: procedural</h2>
    <h2>The fifth major virtue: error-friendly</h2>
    <p>The other major virtues have always
    been objects of theoretical interest --
    they were in fact,
    the reason that the field of theory of algorithms
    was developed.
    </p>
    <p>
    But theoreticians assumed that programmers always
    started with the grammar they intended to use,
    and never made a mistake.
    And theoreticians further assumed that if an input
    was wrong,
    it was enough for the parser to say so.
    It was assumed the programmer would be able to look
    at an input several meg long,
    instantly spot the error,
    mutter "silly me"
    correct it and rerun.
    </p>
    In practice, parsers were as helpful as they could be,
    and programmers had been satisfied with that.
    Regular expressions and their inputs
    usually can be debugged by experiment,
    when the problem is not obvious.<footnote>
    It perhaps helps that regular expressions are less powerful,
    so the problems tend to be simpler.
    There are regex debuggers, but the fact they are not used
    much indicates, at least to this writer, that they aren't needed
    that much</footnote>
    Recursive descent is procedural, and debugging can be approached that
    way.
    </p>
    <p>
    It was assumed, therefore that LALR only had to be as helpful
    as it could be and users would cope.
    But LALR stretched this assumption to the limit.
    </p>
    Recursive descent
    [ TO HERE ] <br>
    This would go without saying,
    except that solutions to the parsing problem are often advanced
    which trade power for reliability.
    An algorithm which can go quadratic or worse is often used to supplement
    an algorithm which lacks power.
    It's a kind of cross-breeding of algorithms.
    The hope is that the hybrid, in your use case,
    had the power of the slow algorithm and the
    speed of the fast one.
    This works a lot better in botany than it does in parsing.
    Once you have a successful cross in a plant,
    you can breed from that and expect good things.
    But if even once you've lucked out with a parse,
    your next parse is a just another new toss of the dice.
    </p>
    <p>In 19XX it was thought the next step up in power,
    consistent with the Three Basic Virtues,
    might have been found:
    A parser called yacc parsed a class of grammars called LALR.
    LALR clearly had two of the Basic Virtues (fast and reliable)
    and it could be said to have the third if you were willing to stretch a point.
    Technically,
    it took a mathematician to tell if a grammar is LALR.
    But what was probably the most sophisticated LALR grammar was
    created by Larry Wall, a non-mathematician --
    so one could get sense of it after a few hard knocks.
    </p>
    <h2>References, comments, etc.</h2>
    <p>
      For more about
      Marpa, my own parsing project,
      there is the
      <a href="http://savage.net.au/Marpa.html">semi-official web site, maintained by Ron Savage</a>.
      The official, but more limited, Marpa website
      <a href="http://jeffreykegler.github.io/Marpa-web-site/">is my personal one</a>.
      Comments on this post can be made in
      <a href="http://groups.google.com/group/marpa-parser">
        Marpa's Google group</a>,
      or on our IRC channel: #marpa at freenode.net.
    </p>
    <comment>FOOTNOTES HERE</comment>
  </body>
</html>
