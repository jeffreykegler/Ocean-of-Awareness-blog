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
    <p>
    A <a href="http://www.rntz.net/post/2018-07-10-parsing-list-comprehensions.html">recent
    blog post by Michael Arntzenius</a> ended with a friendly challenge to Marpa.
    Haskell list comprehensions are a part of Haskell parsing that
    Haskell does not handle very well.
    Michael wondered aloud if Marpa could do better.
    </p>
    <p>In responding, I hope that I answer another challenge as well:
    I claim that Marpa tackles a large class of grammars --
    LR-regular, well beyond what traditional parsers can handle --
    in linear time and without lookahead or backtracking.
    To some ears, this sounds a bit like magical thinking,
    and that fact that this claims is based on papers<footnote>
    TODO
    </footnote>
    in the
    refereed literature has not entirely dispelled the skepticism.
    </p>
    <p>
    In this post I hope to appeal to "programmer common
    sense" in a way similar to recursive descent does --
    to show that,
    the basic idea is no mystery and that,
    while the full implementation
    involves a lot tedious details,
    there is no reason to doubt that the basic method can work.
    </p>
    <h2>The challenge</h2>
    <pA central point of Michael's critique of Haskell's parsing is
    that Haskell's list comprehension could be even more powerful if not
    for syntactic limits.
    As it is, list comprehension in Haskell is impressive.
    <h2>Generators</h2>
    Here is one example,
    from the test case for this blog post:
    <pre><tt>
    list = [ x | [x, 1729,
		      -- insert more here
		      99
		   ] <- xss ]</tt><footnote>
    TODO
    </footnote></pre>
    This says to build a lists of <tt>x</tt>'s
    such that the condition (called a "guard"
    in Haskellese) holds.
    The guard is <tt>[x, 1729, 99 ] &lt;- xss</tt>.
    This kind of guard is called a "generator".
    The <tt>&lt;-</tt> means "draw from".
    The LHS of the <tt>&lt;-</tt> operator is a pattern
    (called &lt;pat&gt; in the syntax),
    and the RHS is an expression.
    This generator draws all the elements from <tt>xxs</tt>
    which match the pattern <tt>[x, 1729, 99 ]</tt>.
    In other words. it draws out
    all the elements of <tt>xxs</tt>,
    which are lists of length 3,
    whose 2nd subelement is 1729,
    and whose 3rd subelement is 99.
    </p>
    <p>The variable <tt>x</tt> is set to the 1st subelement.
    <tt>list</tt> will be a list of all those <tt>x</tt>'s.
    </p>
    <p>
    In the test suite, we have
    <pre><tt>
    xss = [ [ 42, 1729, 99 ] ]</tt><footnote>
    TODO
    </footnote></pre>
    so that list becomes <tt>[42]</tt> -- a list
    of one element whose value is 42.
    </p>
    <h3>Boolean guards</h3>
    <p>The other kind of guard of interest to us is a Boolean guard.
    <pre><tt>
      list2 = [ x | [x, 1729, 99] &lt;- xss,
               [x, 1729,
                  -- insert more here
                  99
               ] == ys,
             [ 42, 1729, 99 ] &lt;- xss
             ]</tt><footnote>
    TODO
    </footnote></pre>
    <p>The expression defining <tt>list2</tt>
    has 3 comma-separated guards:
    The first guard is a generator,
    the same one as in the previous example
    defining <tt>list</tt>: <tt>[x, 1729, 99] &lt;- xss</tt>.
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
    ys = [ 42, 1729, 99 ]</tt><footnote>
    TODO
    </footnote></pre>
    so that <tt>list2</tt> is also
    <tt>[42]</tt>.
    </p>
    <p>The above is not a Haskell tutorial, or part of one.
    I am simply trying to put the parsing issue in context,
    and therefore am quite happy to leave a lot of other
    programming issues vague.<footnote>
    TODO
    </footnote>
    <h2>Boolean guards versus generators</h2>
    <p>From the parser's point of view, Boolean guards
    and generators start out looking the same --
    in the examples above, two of our guards start out
    the same -- with the string <tt>[x, 1729, 99 ]</tt>,
    but
    <ul>
    <li>In one case (the Boolean guard),
    <tt>[x, 1729, 99 ]</tt> is the beginning of an expression
    (Haskell syntax item <tt>&lt;exp&gt;</tt>).</li>
    <li>In the other cases (the generators),
    <tt>[x, 1729, 99 ]</tt> is a pattern
    (Haskell syntax item <tt>&lt;pat&gt;</tt>).</li>
    </ul>
    Clearly patterns and expressions can look identical.
    And they can look identical for an arbitrarily long time --
    I tested GHC<footnote>
    </footnote> with the identical expression/pattern prefixes
    thousands of tokens in length -- my virtual memory eventually gives out,
    but GHC never complains.<footnote>
    Note that if the list is extended, the patterns matches and Boolean
    tests fail, so that 42 is no longer the answer.
    From the parsing point of view, this is immaterial.
    </footnote>
    (The comment <tt>insert more here</tt> shows the point at which the
    comma-separated list of integers can be extended.)
    </p>
    <h2>The problem for parsers</h2>
    <p>So Haskell list comprehension presents a problem for parsers.
    A parser must determine whether it is parsing an expression or
    a pattern, but it cannot know this for an arbitrarily long time.
    A parser must keep track of two possibilities at once --
    something traditional parsing has refused to do<footnote>
    As I have pointed out,
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
    At parsing time, GHC treats an ambiguous quard as a
    Boolean.
    Then, if it turns out that is a generator,
    it rewrites it in post-processing.
    This inelegance incurs some real technical debt --
    either a pattern must <b>always</b> be a valid expression,
    or even more trickery must be resorted to.<footnote>
    This account of the state of the art summarizes
    <a href="http://www.rntz.net/post/2018-07-10-parsing-list-comprehensions.html">recent
    Arntzenius's post</a>,
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
    In full detail this method gets a bit tedious,
    and I won't give the details of Earley's algorithm here.<footnote>
    TODO Refer to Wikipedia.
    Also refer to earlier blog post.
    Note that to fulfill Marpa's full claim of linear time for all
    LR-regular grammars, Marpa finds it necessary to use Joop Leo's
    improvement to Earley's algorithm.
    But Joop's improvement is <b>not</b> necessary or useful
    for parsing
    Haskell list comprehension,
    is not used in this example,
    and will not be described in this post.
    </footnote>
    Instead, I'll give an outline of the method,
    one that I think wlll be intuitive to any working programmer.
    <p>
    </p>
    Earley's algorithm maintains an "Earley table"
    which contains an "Earley set".
    Each Earley set
    tracks the possibilities at
    a specific location.
    </p>
    <p>
    Each Earley set contains "Earley items".
    Each Earley item describes progress in one rule of the grammar.
    Each item also records an "origin": the location in the input where
    the rule described in the item began.
    </p>
    <p>
    Here is an example of an Earley item:
    <pre><tt>
      @0-41 module -&gt; body .</tt><footnote>
    TODO
    </footnote></pre>
    Progress in the rule <tt>module -&gt; body</tt> is show with a dot ("<tt>.</tt>").
    The dot is after the rule, indicating that the rule
    <tt>module -&gt; body</tt>
    has been completely recognized.
    The notation <tt>@0-41</tt> indicates that the <b>origin</b>
    is at Earley set 0,
    and that the item is <b>in</b>
    Earley set 41.
    </p>
    <p>
    A rule with a dot is called a "dotted rule".
    If the dot is at the end of the rule,
    as it was in the last example,
    the dotted rule is a "completion".
    If the dot is at the beginning of the rule,
    the dotted rule is a "predicion".
    If the dot is anywhere else,
    we will call the dotted rule
    a "medial rule".
    </p>
    <h2>Building the guard's Earley sets</h2>
    <p>We run a trace of the Earley sets on the following
    list comprehension
    <pre><tt>
	list = [ x | [x, 1729,
                1, 2, 3,
                99
             ] <- xss ]</tt><footnote>
    TODO
    </footnote></pre>
    The full code and full trace can be found
    on Github<footnote>
    The code is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/gh-pages/code/haskell/listcomp_ex.pl">
    https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/gh-pages/code/haskell/listcomp_ex.pl</a>,
    accessed 26 August 2018.
    It output is 
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/gh-pages/code/haskell/listcomp_trace.txt">
    https://github.com/jeffreykegler/Ocean-of-Awareness-blog/blob/gh-pages/code/haskell/listcomp_trace.txt</a>,
    accessed 26 August 2018.
    </footnote>.
    </p>
    <p>
    The list comprehension has only one guard.
    This guard is a generator,
    but the parser cannot know then until it sees the 
    "<tt>&lt;-</tt>" operator.
    The beginning of the guard, including the literals
    "<tt>1729, 1, 2, 3, 99</tt>" could be the start of
    either an expression or a pattern.
    We will start in the middle,
    with the literal "<tt>2</tt>"
    which is in Earley set 33.
    <p>For the scanner to think the string "2" is a
    <tt>&lt;literal&gt;</tt> in Earley set 33,
    a <tt>&lt;literal&gt;</tt> needs to be predicted
    in Earley set 32.
    And in fact, there are two Earley item
    predictions of
    a <tt>&lt;literal&gt;</tt> in
    Earley set 32:
    <pre><tt>
	@32-32 apat -> . literal
	@32-32 aexp -> . literal</tt><footnote>
    TODO
    </footnote></pre>
    We therefore move the dot past
    <tt>&lt;literal&gt;</tt> and add
    these two items to Earley set 33:
    <pre><tt>
	@32-33 aexp -> literal .
	@32-33 apat -> literal .
	</tt><footnote>
    TODO
    </footnote></pre>
    </p>
    <h2>The "secret" of non-determinism</h2>
    <p>And with our very first two Earley items,
    we have found the "secret" of tracking multiple
    possibilites:
    multiple Earley items.
    <tt>&lt;literal&gt;</tt> could be either
    an "atomic expression" (<<tt>&lt;aexp&gt;</tt>) or
    an "atomic pattern" (<<tt>&lt;apat&gt;</tt>).
    In Earley set 32, we have two predictions,
    one for an <<tt>&lt;aexp&gt;</tt> and
    one for an <<tt>&lt;apat&gt;</tt>.
    And in Earley set 33,
    we have a completions for
    <<tt>&lt;aexp&gt;</tt> and
    a completions for
    <<tt>&lt;apat&gt;</tt>.
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
    <h2>Finishing Earley set 33</h2>
    <p>In our grammar,
    an "atomic pattern"
    is a "literal pattern"
    is a plain old "pattern",
    so that the prediction finding one
    means finding all the others.
    We therefore have
    <pre><tt>
	@32-33 apat -> literal .
	@32-33 lpat -> apat .
	@32-33 pat -> lpat .
    </tt><pre>
    Similarly, for expressions,
    an "atomic expression"
    is a "function application"
    is a "lambda abstraction"
    is an "infix expression"
    is a plain old expresion, so that we have
    <pre><tt>
	@32-33 aexp -> literal .
	@32-33 fexp -> aexp .
	@32-33 lexp -> fexp .
	@32-33 infixexp -> lexp .
	@32-33 exp -> infixexp .
    <tt><pre>
    We also have completed a comma-separated sequence
    of either patterns or expressions, which started
    at Earley set 33.
    <pre><tt>
	@26-33 pats1 -> pats1 ',' pat .
	@26-33 exps -> exps ',' exp .
    </tt></pre>
    At Earley set 26, we have two predictions relevant
    to these
    <pre><tt>
	@25-26 aexp -> L0_leftSquare . exps L0_rightSquare
	@25-26 apat -> L0_leftSquare . pats1 L0_rightSquare
    </tt></pre>
    so that we move the dot past the completed sequences to add
    <pre><tt>
	@25-33 apat -> '[' pats1 . ']'
	@25-33 aexp -> '[' exps . ']'
    </tt></pre>
    to Earley set 33.
    These two new medial items, will not be relevant as long
    as we are in a sequence of integer literal --
    they will not complete
    until we see a right square bracket.
    <p>Not a dead end, however, are two predictions
    in Earley set 31.
    <pre><tt>
	@26-31 pats1 -> . pats1 ',' pat .
	@26-31 exps -> . exps ',' exp .
    </tt></pre>
    <p>These predictions, with the completions of
    <tt>&lt;pats1&gt;</tt> and
    <tt>&lt;exps&gt;</tt>
    in Earley set 33 with origin at Earley set 26,
    produce two important new medial rules:
    <pre><tt>
	@26-33 pats1 -> pats1 . ',' pat .
	@26-33 exps -> exps . ',' exp .
    </tt></pre>
    Both of these predict a comma.
    </p>
    <pre>
F105 @32-33 L5c18-20 apat -> literal .
F100 @32-33 L5c18-20 lpat -> apat .
F99 @32-33 L5c18-20 pat -> lpat .
F108 @26-33 L4c14-L5c20 pats1 -> pat + .
F72 @32-33 L5c18-20 aexp -> literal .
F70 @32-33 L5c18-20 fexp -> aexp .
F62 @32-33 L5c18-20 lexp -> fexp .
F61 @32-33 L5c18-20 infixexp -> lexp .
F58 @32-33 L5c18-20 exp -> infixexp .
F81 @26-33 L4c14-L5c20 exps -> exp + .
R107:2 @25-33 L4c12-L5c20 apat -> L0_leftSquare pats1 . L0_rightSquare
R59:1 @32-33 L5c18-20 infixexp -> lexp . qop infixexp
R69:1 @32-33 L5c18-20 fexp -> fexp . aexp
R75:2 @25-33 L4c12-L5c20 aexp -> L0_leftSquare exps . L0_rightSquare
R98:1 @32-33 L5c18-20 pat -> lpat . qconop pat
    </pre>
    <p>This description of the implementation includes many extracts from
    the code.
    For those looking for more detail,
    the full code and test suite for this example are
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    on Github</a>.
    While the comments in the code do not amount to a tutorial, they are
    extensive.
    Readers who like to "peek ahead" are encouraged to do so.
    </p>
    <h2>Conclusion</h2>
    <h2>The code, comments, etc.</h2>
    <p>A permalink to the
    full code and a test suite for this prototype,
    as described in this blog post,
    is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/6c76ffc791d24f4515edea376ac31ad7264a420c/code/haskell">
    on Github</a>.
    I expect to update this code,
    and the latest commit can be found
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    here</a>.
    Links for specific lines of code in this post are usually
    static permalinks to earlier commits.
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
