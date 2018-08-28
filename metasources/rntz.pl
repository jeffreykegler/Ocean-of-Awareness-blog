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
A Haskell challenge
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>The challenge</h2>
    <p>
    A <a href="http://www.rntz.net/post/2018-07-10-parsing-list-comprehensions.html">recent
    blog post by Michael Arntzenius</a> ended with a friendly challenge to Marpa.
    Haskell list comprehensions are something that
    Haskell's own parser handles only with difficulty.
    A point of Michael's critique of Haskell's parsing was
    that Haskell's list comprehension could be even more powerful if not
    for these syntactic limits.
    </p>
    Michael wondered aloud if Marpa could do better.
    It can.
    </p>
    <p>The problem syntax occurs with the "guards",
    a very powerful facility of
    Haskell's list comprehension.
    Haskell allows several kinds of "guards".
    Two of these "guards" can have the same prefix,
    and these ambiguous prefixes can
    be of arbitrary length.
    In other words,
    parsing Haskell's list comprehension requires
    either lookahead of arbitrary length,
    or its equivalent.
    <p>
    <p>To answer Michael's challenge,
    I extended my Haskell subset parser to deal with
    list comprehension.
    That parser, with its test examples, is online.<footnote>
    If you are interested in my Marpa-driven Haskell subset parser,
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/combinator2.html">
    this blog post</a>
    may be the best introduction.
    The code is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    on Github</a>.
    </footnote>
    I have run it for examples thousands of tokens long and,
    more to the point,
    have checked the Earley sets to ensure that Marpa
    will stay linear,
    no matter how long the ambiguous prefix gets.<footnote>
    The Earley sets for the ambigious prefix immediately reach a size
    of 46 items, and then stay at that level.
    This is experimental evidence that the Earley set
    sizes stay constant.
    <br><br>
    And, if the Earley items are examined,
    and their derivations traced,
    it can be seen that
    they must repeat the same Earley item count
    for as long as the ambiguous prefix continues.
    The traces I examined are
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp_trace.out">here</a>,
    and the code which generated them is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp_ex.pl">here</a>,
    for the
    reader who wants to convince himself.
    <br><br>
    The guard prefixes of Haskell are ambiguous,
    but (modulo mistakes in the standards)
    the overall Haskell grammar is not.
    In the literature on Earley's,
    it has been shown that for an unambiguous grammar,
    each Earley item has an constant amortized cost in time.
    Therefore,
    if a parse produces
    a Earley sets that are all of less than a constant size,
    it must have linear time complexity.
    </footnote>
    </p>
    Earley parsing, which Marpa uses,
    accomplishes the seemingly impossible here.
    It does the equivalent of infinite lookahead efficiently,
    without actually doing any lookahead or
    backtracking.
    That Earley's algorithm can do this has been a settled
    fact in the literature for some time.
    But today Earley's algorithm is little known even
    among those well acquainted with parsing,
    and to many claiming the equivalent of infinite lookahead,
    without actually doing any lookahead at all,
    sounds like a boast of magical powers.
    </p>
    <p>
    In the rest of this blog post,
    I hope to indicate how Earley parsing follows more than
    one potential parse at a time.
    I will not describe Earley's algorithm in full.<footnote>
    There are many descriptions of Earley's algorithm out there.
    <a href="https://en.wikipedia.org/wiki/Earley_parser">The
    Wikipedia page on Earley's algorithm</a>
    (accessed 27 August 2018)
    is one good place to start.
    I did
    another very simple introduction to Earley's in
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2010/06/jay-earleys-idea.html">an
    earlier blog post</a>,
    which may be worth looking at.
    Note that Marpa contains
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2011/11/what-is-the-marpa-algorithm.html">
    improvements to Earley's algorithm</a>.
    Particularly, to fulfill Marpa's claim of linear time for all
    LR-regular grammars, Marpa uses Joop Leo's speed-up.
    But Joop's improvement is <b>not</b> necessary or useful
    for parsing
    Haskell list comprehension,
    is not used in this example,
    and will not be described in this post.
    </footnote>
    But I will show that no magic is involved,
    and that in fact the basic ideas behind Earley's method
    are intuitive and reasonable.
    </p>
    <h2>A quick cheat sheet on list comprehension</h2>
    <p>
    List comprehension in Haskell is impressive.
    Haskell allows
    you to build a list using a series of "guards",
    which can be of several kinds.
    The parsing issue arises because two of the guard types --
    generators and boolean expressions --
    must be treated quite differently,
    but can look the same over an arbitrarily long prefix.
    </p>
    <h3>Generators</h3>
    <p>Here is one example of a Haskell generator,
    from the test case for this blog post:
    </p>
    <pre><tt>
          list = [ x | [x, 1729,
		      -- insert more here
		      99
		   ] <- xss ] </tt><footnote>
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp.t#L30">
    Permalink to this code</a>,
    accessed 27 August 2018.
    </footnote></pre>
    <p>
    This says to build a lists of <tt>x</tt>'s
    such that the guard
    <tt>[x, 1729, 99 ] &lt;- xss</tt>
    holds.
    The clue that this guard is a generator is the
    <tt>&lt;-</tt> operator.
    The <tt>&lt;-</tt> operator
    will appear in every generator,
    and means "draw from".
    </p>
    <p>
    The LHS of the <tt>&lt;-</tt> operator is a pattern
    and the RHS is an expression.
    This generator draws all the elements from <tt>xss</tt>
    which match the pattern <tt>[x, 1729, 99 ]</tt>.
    In other words, it draws out
    all the elements of <tt>xss</tt>,
    and tests that they
    are lists of length 3
    whose last two subelements are 1729 and 99.
    </p>
    <p>The variable <tt>x</tt> is set to the 1st subelement.
    <tt>list</tt> will be a list of all those <tt>x</tt>'s.
    In the test suite, we have
    <pre><tt>
    xss = [ [ 42, 1729, 99 ] ] </tt><footnote>
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp.t#L25">
    Permalink to this code</a>,
    accessed 27 August 2018.
    </footnote></pre>
    </p>
    so that list becomes <tt>[42]</tt> -- a list
    of one element whose value is 42.
    </p>
    <h3>Boolean guards</h3>
    <p>Generators can share very long prefixes with Boolean guards.
    <pre><tt>
	list2 = [ x | [x, 1729, 99] &lt;- xss,
               [x, 1729,
                  -- insert more here
                  99
               ] == ys,
             [ 42, 1729, 99 ] &lt;- xss
             ] </tt><footnote>
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp.t#L35">
    Permalink to this code</a>,
    accessed 27 August 2018.
    </footnote></pre>
    </p>
    <p>The expression defining <tt>list2</tt>
    has 3 comma-separated guards:
    The first guard is a generator,
    the same one as in the previous example.
    The last guard is also a generator.
    </p>
    <p>
    The middle guard is of a new type: it is a Boolean:
    <tt>[x, 1729, 99 ] == ys</tt>.
    This guard insists that <tt>x</tt> be such that the triple
    <tt>[x, 1729, 99 ]</tt> is equal to <tt>ys</tt>.
    </p>
    <p>
    In the test suite, we have
    <pre><tt>
    ys = [ 42, 1729, 99 ] </tt><footnote>
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp.t#L28">
    Permalink to this code</a>,
    accessed 27 August 2018.
    </footnote></pre>
    so that <tt>list2</tt> is also
    <tt>[42]</tt>.
    </p>
    <h2>Boolean guards versus generators</h2>
    <p>From the parser's point of view, Boolean guards
    and generators start out looking the same --
    in the examples above, three of our guards start out
    the same -- with the string <tt>[x, 1729, 99 ]</tt>,
    but
    <ul>
    <li>in one case (the Boolean guard),
    <tt>[x, 1729, 99 ]</tt> is the beginning of an expression; and </li>
    <li>in the other two cases (the generators),
    <tt>[x, 1729, 99 ]</tt> is a pattern.</li>
    </ul>
    Clearly patterns and expressions can look identical.
    And they can look identical for an arbitrarily long time --
    I tested the <a href="https://www.haskell.org/ghc/">Glasgow Haskell Compiler</a>
    (GHC)
    with identical expression/pattern prefixes
    thousands of tokens in length -- my virtual memory eventually gives out,
    but GHC itself never complains.<footnote>
    Note that if the list is extended, the patterns matches and Boolean
    tests fail, so that 42 is no longer the answer.
    From the parsing point of view, this is immaterial.
    </footnote>
    (The comments "<tt>insert more here</tt>" show the points at which the
    comma-separated lists of integers can be extended.)
    </p>
    <h2>The problem for parsers</h2>
    <p>So Haskell list comprehension presents a problem for parsers.
    A parser must determine whether it is parsing an expression or
    a pattern, but it cannot know this for an arbitrarily long time.
    A parser must keep track of two possibilities at once --
    something traditional parsing has refused to do.
    As I have pointed out<footnote>
    In several places, including
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/07/knuth_1965_2.html">
    this blog post</a>.
    </footnote>,
    belief that traditional parsing "solves" the parsing problem is
    belief in human exceptionalism --
    that human have calculating abilities that Turing machines do not.
    Keeping two possibilites in mind for a long time is trivial for
    human beings -- in one form we call it worrying,
    and try to prevent ourselves from doing it obsessively.
    But it has been the orthodoxy that practical parsing algorithms
    cannot do this.
    </footnote>
    </p>
    <p>Arntzenius has a nice summary of the attempts to parse this
    construct while only allowing one possibility at a time --
    that is, determistically.
    Lookahead clearly cannot work -- it would have to be arbitrarily
    long.
    Backtracking can work, but can be very costly
    and is a major obstacle to quality error reporting.
    </p>
    <p>
    GHC avoids the problems with backtracking by using post-processing.
    At parsing time, GHC treats an ambiguous guard as a
    Boolean.
    Then, if it turns out that is a generator,
    it rewrites it in post-processing.
    This inelegance incurs some real technical debt --
    either a pattern must <b>always</b> be a valid expression,
    or even more trickery must be resorted to.<footnote>
    This account of the state of the art summarizes
    <a href="http://www.rntz.net/post/2018-07-10-parsing-list-comprehensions.html">
    Arntzenius's recent post</a>,
    which should be consulted for the details.
    </footnote>
    <h2>The Earley solution</h2>
    </p>
    <p>Earley parsing deals with this issue by doing what 
    a human would do --
    keeping both possibilities in mind at once.
    Jay Earley's innovation was to discover a way for a computer
    to track multiple possible parses
    that is compact,
    efficient to create,
    and efficient to read.
    </p>
    <p>
    Earley's algorithm maintains an "Earley table"
    which contains "Earley sets",
    one for each token.
    Each Earley set contains "Earley items".
    Here are some Earley items from Earley set 25 
    in one of our test cases:<br>
    <pre><tt>
	origin = 22; &lt;atomic expression&gt; ::=   '[' &ltexpression&gt; '|' . &ltguards&gt; ']'
	origin = 25; &lt;guards&gt; ::= . &lt;guard<&gt;
	origin = 25; &lt;guards&gt; ::= . &lt;guards&gt; ',' &lt;guard<&gt;
	origin = 25; &lt;guard<&gt;  ::= . &lt;pattern&gt; '&lt; &lt;expression&gt;
	origin = 25; &lt;guard<&gt;  ::= . &lt;expression&gt; </tt><footnote>
     Adapted from
     <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp_trace.out#L811">
     this trace output</a>,
     accessed 27 August 2018.
     </footnote></pre>
     <p>
     In the code, these represent the state of the parse just after
     the pipe symbol ("<tt>|</tt>") on line 4 of our test code.
    </p>
    Each Earley item describes progress in one rule of the grammar.
    There is a dot ("<tt>.</tt>") in each rule,
    which indicates how far the parse
    has progressed inside the rule.
    One of the rules has the dot just after the pipe symbol,
    as you would expect, since we have just seen a pipe symbol.
    </p>
    <p>
    The other four rules have the dot at the beginning of the RHS.
    These four rules are "predictions" -- none of their symbols
    have been parsed yet, but we know that these rules might occur,
    starting at the location of this Earley set.
    </p>
    <p>
    Each item also records an "origin": the location in the input where
    the rule described in the item began.
    For predictions the origin is always the same as the Earley set.
    For the first Earley item, the origin is 3 tokens earlier,
    in Earley set 22.
    </p>
    <p>
    <h2>The "secret" of non-determinism</h2>
    <p>
    And now we have come to the secret of efficient non-deterministic parsing --
    a "secret"
    which I hope to convince the reader is not magic,
    or even much of a mystery.
    Here, again, are two of the items from Earley set 25:</p>
    <pre><tt>
	origin = 25; &lt;guard<&gt;  ::= . &lt;pattern&gt; '&lt; &lt;expression&gt;
	origin = 25; &lt;guard<&gt;  ::= . &lt;expression&gt; </tt> <footnote>
     Adapted from
     <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp_trace.out#L811">
     this trace output</a>,
     accessed 27 August 2018.
     </footnote></pre>
    </p>
    <p>At this point there are two possibilities going forward --
    a generator guard or a Boolean expression guard.
    And there is an Earley item for each of these possibilities in the Earley set.
    </p>
    <p>
    That is the basic idea -- that is all there is to it.
    Going forward in the parse, for as long as both possibilities stay
    live, Earley items for both will appear in the Earley sets.
    </p>
    <p>From this point of view,
    it should now be clear why the Earley algorithm can keep track
    of several possibilities without lookahead or backtracking.
    No lookahead is needed because all possibilities are in the
    Earley set, and selection among them will take place as the
    rest of the input is read.
    And no backtracking is needed because every possibility
    was already recorded -- there is nothing new to be found
    by backtracking.
    </p>
    <p>It may also be clearer why I claim that Marpa is left-eidetic,
    and how the Ruby Slippers work.<footnote>
    For more on the Ruby Slippers see
    my <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/combinator2.html">
    just previous blog post</a>,
    </footnote>
    Marpa has perfect knowledge of everything in the parse so far,
    because it is all in the Earley tables.
    And, given left-eidetic knowledge, Marpa also knows what
    terminals are expected at the current location,
    and can "wish" them into existence as necessary.
    </p>
    <h2>The code, comments, etc.</h2>
    <p>A permalink to the
    full code and a test suite for this prototype,
    as described in this blog post,
    is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell">
    on Github</a>.
    In particular,
    the permalink of the
    the test suite file for list comprehension is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell/listcomp.t">
    here</a>
    I expect to update this code,
    and the latest commit can be found
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    here</a>.
    </p>
    <p>
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
