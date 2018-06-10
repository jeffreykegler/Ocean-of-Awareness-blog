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
A new way to look at parsing
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Derivatives == Earley?</h2>
    <p>In a very cordial Twitter exchange with Matt Might and
    and David Darais, Prof. Might asked if I would be interesting
    in looking at his derivatives-based approach.
    I answered that I already was --
    I see
    Marpa as an optimized version of the Might/Darais approach.
    </p>
    <p>This may sound strange.
    At first glance, our two algorithms seem about as different as
    parsing algorithms can get.
    My Marpa parser is an Earley parser, table-driven,
    and its parse engine is written in C language.
    The MDS (Might/Darais/Spiewak) parser is
    an extension of regular expressions
    which constructs states on the fly.
    MDS uses combinators and has implementations
    in several functional programming languages.
    </p>
    <h2>Grammar Flow Graphs</h2>
    <p>Why then do I imagine that Marpa is an optimized version of the MDS
    approach?
    The reason is a paper sent to
    me by Prof. Keshav Pingali at Austin: "Parsing with Pictures".
    The title is a little misleading:
    their approach is not <b>that</b> easy,
    and the paper does require some math.
    But it is a lot easier than the traditional way
    of learning the various approaches to parsing.
    </p>
    <p>The basis of the Pingali-Bilardi approach
    is the Grammar Flow Graph (GFG).
    These GFGs are the "pictures" of their title.
    GFGs are NFAs with recursion added.
    As has long been known,
    adding recursion to NFAs
    allows them to represent any context-free language.
    </p>
    <p>Pingali and Bilardi's next step is new.
    A GFG can be "simulated" using the same algorithm
    used to simulate an NFA.
    Hoswever, the result is not immediately impressive.
    The simulation does produce a recognizer, but not a good recognizer:
    Some of the strings recognized by
    the GFG simulator
    are not in the context-free language.
    </p>
    <p>To repair their "simulation",
    Pingali and Bilardi add a tag to each state.
    This tag tracks where the recursion began.<footnote>
    Pingali and Bilardi 2015, p. 11.
    </footnote>.)
    This fixes the recognizer.
    Also, the added information is enough to allow the set
    of parse trees to be efficiently recovered from the
    sets of GFG states.
    </p>
    <p>
    In other words, with tags, the GFG recognizer now is a parser.
    And it turns out that this parser is not new.
    In fact, it is <b>exactly</b> Earley's algorithm.
    </p>
    <p>Pingali and Bilardi do not stop there.
    Using their new framework,
    they go on to show that all LL-based and LR-based algorithms
    are simplifications of their Earley parser.
    From this point of view,
    Earley parsing is the foundation of all context-free parsing,
    and LL- and LR-based algorithms are Earley optimizations.
    <h2>Step 1: the MDS algorithm</h2>
    <p>
    To show that Marpa is an optimization of the MDS approach,
    I will start with the MDS algorithm, and attempt to optimize it.
    For its functional programming language,
    the MDS paper uses Racket.
    The MDS parser is described directly,
    in the usual functional language manner,
    as a matching
    operation.
    </p>
    <p>
    In the MDS paper,
    the MDS parser is optimized with laziness and memoization.
    Nulls are dealt with by computing their fixed points on the fly.
    Even with these three optimizations,
    the result is still highly inefficient.
    So,
    as an additional step, MDS also
    implements "deep recursive simplication" -- in effect,
    strategically replacing laziness with eagerness.
    With this the MDS paper conjectures that the algorithm's time
    is linear for a large class of practical grammars.
    </p>
    <h2>Step 2: Extended regular expressions</h2>
    <p>
    Next, we notice that the context-free grammars
    of the MDS algorithm 
    are regular expressions extended to allow recursion.
    Essentially, they are 
    GFG's translated into Racket match expressions.
    The equivalence is close enough that
    you could imagine the MDS paper using GFG's
    for its illustrations.
    </p>
    <h2>Step 3: Simulating an NFA</h2>
    <p>
    Unsurprisingly, then,
    the MDS and GFG approaches are similar in their next step.
    Each consumes a single character to produce a
    "partial parse".
    A partial parse, for our both of these algorithms,
    can be represented as a duple.
    One element of the duple is a string representing the
    unconsumed input.
    The other is a representation of a set of parse trees.
    In the case of MDS,
    in keeping with its functional approach,
    the set of parse trees is represented directly.
    In the case of the GFG-simulator,
    the set of parse trees is compressed into a sequence of
    GFG-state-sets.
    There is one GFG-state-set for the start of parsing,
    and one for each consumed character.
    </p>
    <h2>Step 3: Earley's Algorithm</h2>
    <p>At this point,
    with the introduction of the GFG state-sets to represent parse-trees,
    the MDS algorithm and its optimized GFG equivalent have
    "forked".
    Recall from above,
    that this GFG simulator has a bug --
    it is over-liberal.
    We fix this bug by tagging each GFG state with the
    the index of the GFG state-set which begins the recursion
    it is part of.
    With these tags,
    the GFG state-sets are exactly Earley sets.
    <h2>Step 3: The Leo optimization</h2>
    <p>Next we incorporate an optimization by Joop Leo,
    which makes Earley parsing linear for all LR-regular grammars,
    without using lookahead.
    Since LR-regular includes LR and LL, including LL(*),
    we do not bother with lookahead.
    We therefore ignore the optimizations described in the later pages
    of Pingali and Bilardi.
    </p>
    <h2>Step 3: Marpa</h2>
    <p>To get from an Earley/Leo parser to a Marpa parser,
    we need to address one more major point.
    In modern parsing practice,
    programmers expect the ability to introduce procedural logic,
    even to the point of switching parsers.
    By ensuring that processing each Earley set is complete
    before processing on the next Earley set begins,
    we accomplish this.
    </p>
    <p>
    This means that Marpa has available full information
    about the parse so far -- it is left-eidetic.
    Error reporting is unexcelled,
    and procedural logic can use this information as well.
    For example,
    full parse information implies full knowledge of which
    tokens are expected next.
    </p>
    <p>
    This means that you can write an liberal HTML parser,
    starting with a very illiberal HTML grammar.
    When the illiberal parser encounters a point where it cannot
    continue because of a missing token,
    procedural logic can ask
    what the expected token is,
    concoct it on they fly,
    supply it to the illiberal parser,
    and ask the illiberal parser to continue.
    This is called the "Ruby Slippers" technique,
    and an HTML parser based on it has been implemented.
    </p>
    <h2>The way forward</h2>
    <p>
    As mentioned,
    the MDS algorithm has its own approach to optmization,
    one which takes maximum advantage of functional programming.
    In contrast, Marpa relies on C level coding.
    </p>
    <p>One example of the contrast in optimization techniques
    is null handling.
    Recall from above that, to deal with null processing,
    the MDS algorithm uses a fixed-point
    algorithm on the fly.
    Marpa, on the other hand,
    before parsing begins.
    precomputes a list of nullable
    symbols using bit vectors.
    In this particular case, Marpa will usually be the winner.
    </p>
    <p>A second case in which hand optimization wins is the
    all-important Leo optimization.
    Simon Peyton-Jones is a very smart man,
    but nonetheless I believe that
    the day that GHC will look at a functional specification
    of an Earley parser and rediscover the Leo optimization
    at compile time is far off.
    </p>
    <p>
    On the other hand,
    I do not imagine that hand optimization and/or C language is the
    winner in all cases.
    A programmer who imagines that he can spot all the cases where
    lazy evaluation or memoization will be effective in the general case
    is deceiving himself.
    And of course,
    even an omniscient programmer is not going to be there at run-time
    for "just in time" optimization.
    Perhaps the optimal parser of the future will combine important hand optimizations
    with functional programming.
    </p>
    <h2>Comments, etc.</h2>
    <p>
      To learn about Marpa,
      my Earley/Leo-based parsing project,
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
