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
The Seven Virtues of Parsers
<html>
  <head>
  </head>
  <body>
    <p>
      <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
      In a previous post<footnote>
        Much of the material in this post is drawn from
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
      what causes users to want a better one?
    </p>
    <p>Comparisons of parsers are often like a variant
      of archery
      where the archer is allowed to move
      the target after shooting the bow.
      It is my purpose in this post to escape that,
      and to ground comparison in the experience of
      practical programmers,
      as shown by the history of the field<footnote>
      No single set of criteria applies to all parsing
      tasks.
      The criteria in this post are for a programmer's
      most powerful toolbox parser.
      Recursive descent and PEG will
      probably survive forever in specialized uses.
      And the most frequently used parser
      will probably always be regexes.
      </footnote>.
    </p>
    <h2>The first major virtue: fast</h2>
    <p>
      From one point of view,
      the first systematic attempt at parsing
      was via regular expressions.<footnote>
        Strictly speaking,
        regular expressions are recognizers,
        not parsers
        (see "Term: parser" and
        "Term: recognizer" in
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
	"Parsing: A Timeline", V3</a>).
          This is because, in their pure form, regular expressions
          simply determine if the input is a match --
          they do not determine its structure.
          Nonetheless, regex engines in practical use
          often extend regular expressions,
          for example, by adding captures.
          At the low end, regexes often compete with parsers
          and why that is the case is very relevant to my
          concerns in this post.</a></footnote>
      Regular expressions show no signs of going away,
      so they obviously demonstrate at least
      <b>some</b>
      of the virtues that make a parser popular.
    </p>
    <p>
      The most obvious of these is that
      a parser must be "fast enough"
      to please its users.
      A rigorous understanding of what "fast enough" means
      was slow to emerge,
      but it is now clear that, except in specialized uses,
      it means that a parser must be linear or quasi-linear.<footnote>
        For more about "linear" and "quasi-linear",
	including definitions,
        see the 'Term: linear' section of
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
      Regular expressions as predictable as
      you could possibly want --
      there's a handy notation for them.
      Anything in that notation is a regular expression,
      and will be parsed in linear time by your regular
      expression engine --
      you never need to desk-check.
    </p>
    <h2>The first minor virtue: declarative</h2>
    <p>If a parser can automatically be generated from a compact
      notation, I say that it has the first minor
      virtue: it is "declarative".
      There is a exact notation
      for regular expressions,
      so and it is so handy that it is almost always
      used to drive regular expression parsing.
      Regular expression is as declarative as it gets.
    </p>
    <h2>The third major virtue: power</h2>
    <p>Regular expressions, however,
      were not the end of the parsing story.
      If a programmer has a grammar she considers practical,
      she wants her parser to parse it.
      Here regular expressions often fail -- a lot of practical
      grammars are regular expressions, but many others are not.
      For regular expressions,
      one of the fails is ironic --
      the notation for regular expressions is recursive,
      but regular expressions cannot deal with recursion.
    </p>
    <p>
      The first paper
      fully describing a parser is Irons 1961,
      and it contains the most
      ambitious grab for parsing power up to that time.
      The Irons parser is "general",
      meaning that it can parse all of what what are called
      the "context-free grammars".
    </p>
    <p>
      The context-free grammars many of the nice properties
      with regular expressions.
      There is a very handy notation for them: BNF.
      Anything you can write in BNF is a context-free grammar.
      Any grammar you cannot write in BNF is not context-free.
      This makes the Irons parser as predictable as regular
      expressions.
      But the Irons parser is far more powerful:
      The context-free grammars are vastly larger than
      the regular expression grammars,
      which they contain.
    </p>
    <h2>The fourth major virtue: reliable</h2>
    <p>
      The Irons 1961 algorithm was perfectly predictable.
      It was predictably powerful.
      And for some grammars it was fast.
      </p>
      <p>
      But Irons 1961 was not predictably fast.
      In the general case,
      Irons 1961 used backtracking
      to achieve its power,
      so it would go exponential for many useful grammars.
      Irons 1961 was not reliably fast.
    </p>
    <h2>The second minor virtue: procedural</h2>
    <p>
      Among the grammars Irons 1961 could not parse quickly
      were those containing the all-important arithmetic expressions.
      So Irons 1961 gave way to recursive descent.
      Recursive descent in its pure form,
      could not parse arithmetic expressions at all,
      but it made up for that by having the second minor virtue:
      it was "procedural",
      that is, it could be customized with procedural code.
      Recursive descent itself was not reliable for arithmetic
      expressions, but it could call specialized parsers which were
      reliably fast for those sections of the input.
    </p>
    <p>
      Traditionally, the two minor virtues has been seen as
      opposites -- you either write code to parse,
      or you declare a grammar specification and parse from
      that.
      So recursive descent traded an unproductive virtue
      for a useful one.
    </p>
      I am the virtues of being declarative and being procedural
      "minor" because, while the major virtues must all be present to some
      extent, history shows the programmer community will
      live without the minor virtues when it believes it has to.
      This has certainly been the case for declarative parsing.
      But it is also important to note that
      the desire for declarative parsing, once awakened by Chomsky,
      has never died.
      The repeated failures at practical declarative parsing
      has never discouraged new attempts.
    </p>
    <p>
      In fact, in 1969 it was thought this problem was solved.
      LALR was not only a
      step up in power from recursive descent --
      it was declarative.
      (Most practitioners will know LALR as the parse engine behind
      <tt>yacc</tt> and <tt>bison</tt>.)
      LALR clearly was fast and reliable -- if it parsed
      a grammar, it always did so in linear time.
      And LALR could be said to be predictable
      if you were willing to stretch the definition a bit.
      The description of the LALR class of grammars is very
      technical. In the general case,
      it takes some mathematics to know
      if a grammar is LALR.
    </p>
    <p>
      But one could deal with LALR as if it was a pinball machine --
      there's no exact definition of how much nudging you're allowed,
      but with practice you acquire a sense for what you
      can get away with.
      In fact,
      the most aggressive
      widely-used LALR grammar was written
      by Larry Wall, a linguist by training.
    </p>
    <h2>The fifth major virtue: error-friendly</h2>
    <p>The first four major virtues have always
      been objects of theoretical interest --
      they were in fact,
      the reason that the field of theory of algorithms
      was developed.
      But theoreticians had usually ignored the fifth virtue --
      that of being error-friendly, or at least error-tolerant.
    </p>
    <p>
      Theoreticians had assumed that programmers always
      started with the grammar they intended to use,
      and never made a mistake.
      And theoreticians further assumed that if an input
      was wrong,
      it was enough for the parser to say so.
      It was assumed the programmer could glance
      at an input several meg long,
      instantly spot the problem,
      mutter "silly me",
      correct it and rerun.
    </p>
    <p>
      In practice, parsers were as helpful as they conveniently could be,
      and programmers had been satisfied with that.
      Regular expressions and their inputs
      usually can be debugged by experiment,
      when the problem is not obvious.<footnote>
        It perhaps helps that regular expressions are less powerful,
        so the problems tend to be simpler.
        There are regex debuggers, but the fact they are not used
        much indicates, at least to this writer, that they aren't needed
        that much.</footnote>
      Recursive descent is procedural, and debugging can be approached that
      way.
    </p>
    <p>
      The advent of LALR in 1969 stretched things to,
      and ultimately beyond, the breaking point.
      It was assumed that, as before, 
      LALR only had to be as helpful
      as it could be and users would cope.
      But LALR carried error-unfriendliness to extremes.
      LALR did not necessarily detect errors immediately.
      When it did recognize an error,
      it described the problem in terms of LR(1) states.
      You need a fair amount of parsing theory to understand these.
      Alas, for the programmer willing to do this,
      another pitfall awaited.
      Since LALR was a simplification of LR(1),
      the LR(1) state conflicts it reported did not necessarily exist --
      that is, the error reports, cryptic as they were,
      were sometimes just plain wrong.<footnote>
        See Grune and Jacobs,
        <cite>Parsing Techniques: A Practical Guide</cite>,
        2nd edition, 2008,
        p. 314.
      </footnote>
    </p>
    <p>Despite its toxic qualities,
      LALR dominated practice for at least a decade,
      ruled the textbooks for longer
      and still plays a disproportionate role in
      classroom instruction<footnote>
        I understand that compiler and parsing courses,
        once required of all grad students,
        are now either optional
        or no longer taught,
        even in some of the top Computer Science departmennts.
        This IMHO would be one of the reasons.
      </footnote>.
    </p>
    <h2>Revisiting reliability</h2>
    <p>
      [ FRAGMENT ] <br>
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
    <h2>Marpa</h2>
    <p>
       As many readers will be aware,
       I have my own pony in this horse-race.
       I have described how it relates to these virtues
       elsewhere<footnote>
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
	My V3 timeline</a>,
	very popular on its own account,
	and backgroun source of much of this post,
	also describes how Marpa (my own parser)
	relates to these "virtues".
	See also the links at the end of this blog post.
       </footnote>.
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
