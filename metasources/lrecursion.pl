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
Parsing left recursions
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Left recursion</h2>
    <p>A lot has been written about parsing left recursion.
    Unfortunately, much of it simply adds to the mystery.
    In this post, I hope to frame the subject clearly and briefly.
    <p>
    </p>I expect the reader has some idea of what left recursion is,
    and perhaps some experience of it as an issue.
    Informally, left recursion occurs when a symbol expands to something
    with itself on the left.
    This can happen directly, for example, if
    production <tt>(1)</tt> is in a grammar.
    </p>
    <pre><tt>
    (1) A ::= A B
    </tt></pre>
    Indirect left recursion happens when,
    for example,
    <tt>(2)</tt> and
    <tt>(3)</tt>
    are productions in a grammar.
    <pre><tt>
    (2) A ::= B C
    (3) B ::= A D
    </tt></pre>
    A grammar with productions
    <tt>(4)</tt> and
    <tt>(5)</tt>
    has a "hidden" left recursion.
    <pre><tt>
    (4) A ::= B A C
    (5) B ::= # empty
    </tt></pre>
    This is because
    <tt>&lt;A&gt;</tt>
    ends up leftmost in derivations like:
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
    <tt>&lt;A&gt;</tt>.
    All recursions can be a problem,
    but left recursions are a particular problem because almost all practical
    parsing methods<footnote>
    I probably could have said "all practical parsing methods"
    instead of "almost all".
    Right-to-left parsing methods exist,
    but they see little use.
    In any case, they only reverse the problem.
    Parsing in both directions is certainly possible but,
    as I will show,
    we do not have to go to quite that much trouble.
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
    That is no coincidence -- as Pingali and Bilardi<footnote>
        Keshav Pingali and Gianfranco Bilardi, UTCS tech report TR-2012.
        2012.
        <a href="https://apps.cs.utexas.edu/tech_reports/reports/tr/TR-2102.pdf">
          PDF accessed 9 Junk 2018</a>.
        <a href="https://www.youtube.com/watch?v=eeZ3URxd8Wc">
          Video accessed 9 June 2018</a>.
        Less accessible is
        Keshav Pingali and Gianfranco Bilardi,
        "A graphical model for context-free grammar parsing."
        Compiler Construction - 24th International Conference, CC 2015.
        Lecture Notes in Computer Science,
        Vol. 9031, pp. 3-27, Springer Verlag, 2015.
        <a href="https://www.researchgate.net/publication/286479583_A_Graphical_Model_for_Context-Free_Grammar_Parsing">
          PDF accessed 9 June 2018</a>.
      </footnote>
    show,
    Earley's, despite its daunting reputation,
    is actually the most basic Chomskyan context-free parsing algorithm,
    the one from which all others derive.
    </p>
    <p>Earley's builds a table.
    The Earley table contains an initial Earley set
    and an Earley set for each token.
    The Earley set for each token
    describes the state of the parse after consuming that token.
    The basic idea is not dissimilar
    to that of the Might/Darais/Spiewak (MDS) idea of parsing by derivatives,
    and the logic for building the Earley sets resembles
    that of MDS.<footnote>
        Matthew Might, David Darais and Daniel Spiewak.
	"Functional Pearl: Parsing with Derivatives."
	International Conference on Functional Programming 2011 (ICFP 2011).
	Tokyo, Japan. September, 2011. pages 189-195.
        <a href="http://matt.might.net/papers/might2011derivatives.pdf">
          PDF accessed 9 Jun 2018</a>.
        <a href="http://matt.might.net/papers/might2011derivatives-icfp-talk.pdf">
          Slides accessed 9 June 2018</a>.
        <a href="http://matt.might.net/media/mattmight-icfp2011-derivatives.mp4">
          Video accessed 9 June 2018</a>.
      </footnote>
    <p>
    For the purpose of studying left recursion,
    what matters is that
    each Earley set contains Earley "items".
    Some of the items are called predictions
    because they predict the occurrence of a symbol
    at that location in the input.
    </p>
    To record a left recursion in an Earley set,
    the program adds
    a prediction item for the left recursive symbol.
    It is that simple.<footnote>
    Those familiar with Earley's algorithm may note that
    Earley items are traditionally in terms of productions,
    not symbols.
    Symbol predictions are therefore recorded indirectly.
    <br><br>
    Specifically, Earley items are traditionally duples
    of <tt>(dr, origin)</tt>,
    where <tt>dr</tt> is a dotted production -- a production
    with a "dot location" marked;
    and <tt>origin</tt> is a location in the input.
    In all predictions <tt>origin</tt> is the current location,
    and the dot location is at the start of the production,
    so there can be at most one prediction per rule.
    A prediction of a symbol 
    <tt>&lt;A&gt;</tt>
    is recorded as a prediction of every
    production which has 
    <tt>&lt;A&gt;</tt> on its LHS.
    <br><br>
    The argument in the main text is made the way it is
    because it is simpler to speak
    of "predicted symbols" than
    to repeatedly refer to "sets of predictions
    of productions sharing a common LHS".
    </footnote>
    </p>
    Multiple occurrences of a prediction item would be identical,
    and therefore useless.
    Therefore subsequent attempts
    to add the same prediction item are ignored,
    and recursion does not occur.
    </p>
    <h2>If some have no problem, why do others?</h2>
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
    In the traditional implementation of recursive descent,
    left recursion is very problematic.
    Suppose that, as part of a recursive descent implementation,
    you are writing the function to parse the
    symbol <tt>&lt;A&gt;</tt>,
    which you are calling
    <tt>parse_A()</tt>.
    If your grammar has a rule
    <pre><tt>
    (9) A ::= A B
    </tt></pre>
    the first thing you need to do in a naive
    implementation of
    <tt>parse_A()</tt>
    is to call <tt>parse_A()</tt>.
    And <tt>parse_A()</tt> will
    then call <tt>parse_A()</tt>.
    And so, in the naive implementation, on and on forever.
    <h2>The fixed-point solution to left recursion</h2>
    <p>Over the years,
    many ways to solve the top-down left recursion issue have been
    announced.
    The MDS solution is one of the more interesting --
    interesting because it actually works<footnote>
    There have been many more attempts than implementations
    over the years,
    and even some of the most-widely used
    implementations <a href="https://www.youtube.com/watch?v=lFBEf0o-4sY&feature=youtu.be&t=6m29s">
    have
    their issues.</a>
    </footnote>,
    and because it describes all the others,
    including the Earley algorithm solution.
    MDS reduces the problem to
    the more general one of finding a "fixed point" of the recursion.
    </p>
    <p>In math, the "fixed point" of a function is an argument of
    the function which is equal to its value for that argument --
    that is, an <tt>x</tt> such that <tt>f(x)&nbsp;=&nbsp;x</tt>.
    MDS describes an algorithm which "solves" the left recursion
    for its fixed point.
    That "fixed point" can then be memoized.
    For example the value of <tt>parse_A</tt>
    can be the memoized "fixed point" value of
    <tt>&lt;A&gt;</tt>.
    </p>
    <p>The Earley solution of left recursion was, in fact, an optimized
    "fixed point".
    The computation of an Earley is the application of a set
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
    and it is expensive.
    In the worst case, the MDS approach is exponential,
    although they conjecture that it is linear for a large
    class of practical grammars.
    </p>
    <p>Top-down algorithms can take an "in-between strategy" --
    they can tackle those left recursions that are cheap to
    find, without computing the full "fixed point".
    Here a well-defined boundary is crucial:
    A programmer wants to know if their particular grammar will
    work,
    and whether small tweaks to their grammar will break it.
    </p>
    <p>
    Top-down can be seen as
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2015/12/topdown.html">
    a "guessing" strategy with hacks</a>.
    Hacks are always needed in top-down, because the input is at the bottom,
    not the top, and a useful top-down algorithm needs to look at the input.
    But the hacks can be as simple as lookahead,
    and lookahead can be implemented without seriously compromising
    the simplicity and flexibility of the original top-down approach.
    </p>
    <p>With detection and fixing of left-recursion,
    the "hack" part of the top-down strategy becomes very complicated.
    The attraction of top-down is its simplicity,
    and its resulting adapability to procedural logic.
    The point can be reached where the original strategy
    comes into question.
    </p>
    <p>
    After all,
    a recursive descent parser can straightforwardly take care of left recursion
    issues by calling an Earley parser.
    But in that case,
    why not simply use Earley's?
    </p>
    <h2>Comments, etc.</h2>
      Marpa is my own implementation of an Earley parser.<footnote>
        Marpa has a stable implementation.
        For it, and for more information on Marpa, there are these resources:<br>
        <a href="http://savage.net.au/Marpa.html">
          Marpa website, accessed 25 April 2018</a>.</br>
        <a href="https://jeffreykegler.github.io/Marpa-web-site/">
          Kegler's website, accessed 25 April 2018</a>.</br>
        <a href="https://github.com/jeffreykegler/Marpa--R2">
          Github repo, accessed 25 April 2018.</a></br>
        <a href="https://metacpan.org/pod/Marpa::R2">
          MetaCPAN, accessed 30 April 2018.</a>.</br>
	  There is also a theory paper for Marpa:
        Kegler, Jeffrey.
        "Marpa, A Practical General Parser: The Recognizer.", 2013.
        <a href="http://dinhe.net/~aredridel/.notmine/PDFs/Parsing/KEGLER,%20Jeffrey%20-%20Marpa,%20a%20practical%20general%20parser:%20the%20recognizer.pdf">
          PDF accessed 24 April 2018</a>.
      </footnote>
      Comments on this post can be made in
      <a href="http://groups.google.com/group/marpa-parser">
        Marpa's Google group</a>,
      or on its IRC channel: #marpa at freenode.net.
    </p>
    <comment>FOOTNOTES HERE</comment>
  </body>
</html>
