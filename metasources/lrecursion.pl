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
    push @fn_lines, qq{<p id="$fn_href"><b>$fn_number.</b>};
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
Why the big deal about left recursion?
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Left recursion</h2>
    <p>This is a lot written about left recursion,
    and frankly much of what has been written adds to the mystery.
    In this post, I hope to frame the subject clearly and briefly.
    <p>
    </p>I assume the reader has some idea of what left recursion is.
    Informally, left recursion occurs when a symbol expands to something
    with itself on the left.
    This can happen directly, for example, if
    </p>
    <pre><tt>
    (1) A ::= A B
    </tt></pre>
    production <tt>(1)</tt> is in a grammar.
    Indirect left recursion happens when,
    for example,
    <pre><tt>
    (2) A ::= B C
    (3) B ::= A D
    </tt></pre>
    <tt>(2)</tt> and
    <tt>(3)</tt>
    are productions in a grammar.
    <pre><tt>
    (4) A ::= B A C
    (5) B ::= # empty
    </tt></pre>
    A grammar with productions
    <tt>(4)</tt> and
    <tt>(5)</tt>
    has a "hidden" left recursion.
    This is because
    <tt>&lt;A&gt;</tt>
    will ends up leftmost in derivations like:
    <pre><tt>
    (6) A  &#10230; B A C &#10230 A C
    </tt></pre>
    In derivation <tt>(6)</tt>,
    production <tt>(4)</tt> was applied,
    then production <tt>(5)</tt>.
    <p>For those into notation,
    a grammar is left recursive if and only if it allows a derivation of the
    form
    <pre><tt>
    (7) A  &#10230;<sup>+</sup> &beta; A &gamma; </tt> where <tt> &beta; = &epsilon;
    </tt></pre>
    In <tt>(7)</tt> <tt>&epsilon;</tt> is the empty string,
    and 
    <tt> &alpha; &#10230;<sup>+</sup> &beta;</tt>
    indicates that <tt>&alpha;</tt> derives <tt>&beta;</tt>
    in one or more rule applications.
    <h2>So, OK, what is the problem?</h2>
    <p>The problem with parsing left recursions is that if you are parsing
    using a derivation like
    <pre><tt>
    (8) A  &#10230; A B </tt>
    </tt></pre>
    then you have defined
    <tt>&lt;A&gt;</tt>
    in terms of 
    <tt>&lt;A&gt;</tt> --
    you have an infinite regress.
    All recursions can be a problem,
    but left recursions are a particular problem because almost all practical
    parsing methods<footnote>
    I probably could have said "all practical parsing methods"
    instead of "almost all".
    Right-to-left parsing methods exist,
    but they see little use,
    in any case, they only reverse the problem.
    Parsing in both directions is certainly possible but,
    as I will show,
    we do not have to go to that much trouble.
    </footnote>
    proceed left to right,
    and derivations like <tt>(8)</tt> will lead many of
    the most popular algorithms straight into
    an infinite regress.
    <h2>Why do some algorithms not have a problem?</h2>
    <p>In a sense,
    all algorithms which solve the left recursion problem do
    it in the same way.
    It is just that in some,
    the solution appears in a much simpler form.
    </p>
    <p>
    The solution is at most simple in Earley's algorithm.
    That is no coincidence -- as Pingali and Bernadi show,
    Earley's, despite its daunting reputation,
    is actually the most basic context-free parsing algorithm.
    </p>
    <p>Earley's builds a table.
    The Earley table contains an initial Earley set
    and an Earley set for each token.
    Each Earley sets
    describes that state of the parse after consuming that token.
    The basic idea is not dissimilar to that of MDS,
    and the logic for building the Earley sets resembles
    that of MDS.<footnote>
    TODO.
    </footnote>
    <p>
    For our purposes, what matter is that
    each Earley set contains items.
    Some of the items are called predictions
    because they predict the occurrence of a symbol
    at that location in the input.
    Left recursions are recorded as predictions of the left
    recursive symbol.
    And that, simple as it is,
    is the Earley's solution to left recursion.
    </p>
    Multiple occurrences of a prediction item would be identical,
    and therefore useless.
    Subsequent attempts
    to add the same prediction item are ignored,
    and recursion does not occur.
    </p>
    <h2>If some do not, why do the others?</h2>
    <p>Besides Earley's,
    a number of other algorithms handle left recursion without
    any issue -- notably LALR 
    (aka <tt>yacc</tt> or <tt>bison</tt>) and LR.
    This re-raises the original question:
    why do some algorithms have a left recursion problem?
    </p>
    <p>The worst afflicted algorithms are the "top-down"
    parsers.
    The best known of these is recursive descent --
    a parsing methodology which, essentially, does parsing
    by calling a subroutine to handle each symbol.
    In a naive implementation of recursive descent,
    left recursion is very problematic.
    To illustrate, if you are writing the function <tt>parse_A()</tt>
    and have a rule
    <pre><tt>
    (9) A ::= A B
    </tt></pre>
    the first thing you need do in
    <tt>parse_A()</tt>.
    is to call <tt>parse_A()</tt>.
    <h2>The fixed-point solution to left recursion</h2>
    <p>Over the years,
    many ways to solve the top-down left recursion issue have been
    announced.
    Recently, I came across one of the more interesting --
    interesting because it describes all the others,
    including the Earley algorithm solution.
    </p>
    <p>
    Might, Darais and Spiewak (MDS) reduce the problem to that
    the more general one of finding a "fixed point" of the recursion.
    </p>
    <p>In math, the "fixed point" of a function is an argument of
    the function which is equal to its value for that argument --
    that is, an <tt>x</tt> such that <tt>f(x) = x</tt>.
    MDS describe an algorithm which "solves" the left recursion
    for its fixed point.
    That "fixed point" can then be memoized.
    For example the value of <tt>parse_A</tt>
    can be the memoized "fixed point" value of
    <tt>&lt;A&gt;</tt>.
    </p>
    <p>Abstractly,
    the computation of an Earley is the application of a set
    of rules for adding Earley items.
    This continues until no more Earley items can be added.
    In other words, the rules for building an Earley set
    are applied until they find
    their "fixed point".<footnote>
    Recall that potential left recursions are 
    recorded as "predictions" in Earley's algorithm.
    Predictions recurse,
    but since they do not depend on the input,
    they can be precomputed.
    This means that Earley implementations can
    bring each Earley set to its fixed point
    very quickly.
    </footnote>
    </p>
    <h2>Other top-down solutions</h2>
    <p>The MDS fixed point solution <b>does</b>
    the job,
    but as described in their paper it requires a functional
    programming language to implement,
    and is not inexpensive.
    There have been many other attempted top-down solutions
    to the left-recursion problem,
    some with a degree of success.
    In retrospect,
    perhaps these can
    be seen as approaches to,
    and usually oversimplifications of,
    the MDS fixed point approach.
    </p>
    <h2>The code, comments, etc.</h2>
      To learn more about Marpa,
      a good first stop is the
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
