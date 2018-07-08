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
Undershoot: Parsing theory in 1965
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <blockquote>The difference between theory and practice is
      that in theory there is no difference between
      theory and practice,
      but in practice, there is.<footnote>
        Attributed to Jan L. A. van de Snepscheut and Yogi Berra.
        See
        <a href="https://en.wikiquote.org/wiki/Jan_L._A._van_de_Snepscheut">
          https://en.wikiquote.org/wiki/Jan_L._A._van_de_Snepscheut</a>,
        accessed 1 July 2018.
        I quote my preferred form  of this --
        the one it takes in
        Doug Rosenberg and Matt Stephens,
        <cite>Use Case Driven Object Modeling with UML: Theory and Practice</cite>,
        2007,
        p. xxvii.
        Rosenberg and Stephens is also the accepted authority for its attribution.
      </footnote>
    </blockquote>
    <p>
      Once it was taken seriously that humans might have the power to, for
      example, "read" a chessboard in a way that computers could not beat.
      This kind of "computational mysticism" has taken a beating.
      But it survives in one last stronghold -- parsing theory.
    </p><p>
      In
      <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">
      a previous post</a>,
      I asked "Why is parsing considered solved?"
      If the state of the art of computer parsing is taken as anything close to its ultimate solution,
      then it is a case of "human exceptionalism" --
      the human brain has some
      power that makes it much better at parsing than computers can be.
      It is very unlikely resorting to human exceptionalism as an explanation
      would be accepted
      for any other problem in computer science.
      Why is it accepted for parsing theory?<footnote>
        As an aside, I am open to the idea that
        the human mind has abilities that Turing machines cannot improve on
        or even duplicate.
        When it comes to
        survival heuristics tied to the needs of human bodies, for example,
        it seems very reasonable to at least entertain the conjecture
        that the human mind might be near-optimal,
        particularly in big-O terms.
        But when it comes to ability to solve problems which can be formalized
        as "puzzles" -- and syntactic analysis is one of these --
        I think that resort to human exceptionalism
	is a sign of desperation.
      </footnote>
    </p>
    <p>
      I addressed this question in
      <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">a previous post</a>.
      It really requires two separate answers:
      "Why do practitioners accept the current state of the art as the solution?"
      And
      "Why do the theoreticians accept the current state of the art as the solution?"
    <p>
    </p>In that previous post,
    I answered the practitioner question in detail,
    but the question about the theoreticians only in outline.
    This post expands on that outline.
    </p>
    <h2>The Practitioners</h2>
    <p>
      To summarize, in 1965,
      <b>practitioners</b>
      accepted the parsing problem as solved
      for the following reasons:
    </p>
    <ul>
      <li>in 1965, every practical parser was stack-driven.</li>
      <li>As of 1965, stacks themselves were quite leading edge.
        As recently as 1961,
        a leading edge article<footnote>
          Oettinger, Anthony. "Automatic Syntactic Analysis and the Pushdown
          Store" Proceedings of Symposia in Applied Mathematics, Volume 12,
          American Mathematical Society, 1961.
          Oettinger describes "push" and "pop"
	  stack operations in "Iversion notation" -- what
          later became APL.
          See the discussion of Oettinger in
          my
          <a href="
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">
            "Why is parsing considered solved?" post</a>.
        </footnote>
	could not assume that its readers knew what "pop" and "push" operations
	were.
      </li>
      <li>An algorithm that combined state transitions and stack operations was
      already a challenge to existing machines.
      In 1965, any more complicated algorithm was likely to be unuseable
      in practice.
      </li>
      <li>Last, but not least, the theoreticians assured the
      practitioners that LR-parsing was either state-of-the-art
      or beyond,
      so making more agressive use of hardware
      would be futile.
      </li>
    </ul>
    <h2>What about the theorists?</h2>
    <p>The practitioners of 1965, then,
    were quite reasonable in feeling that
    LR-parsing was as good as anything they were likely to be able
    to implement any time soon.
    And they were being told by the theorists that,
    in fact,
    it never would get any better --
    there were theoretical limits on parsers that faster
    hardware could not overcome.
    </p>
    <p>We now know that the theorists were wrong --
    there are non-LR parsers which are better than the
    LR parsers are at LR grammars.
    What made the theorists go astray?
    </p>
    <h2>How theorists work</h2>
    <p>As the epigraph for this post reminds us,
    theorists who hope to guide practitioners have to confront a big problem --
    theory is practice only in theory.
    Theoreticians
    (or at least some of the most influential ones)
    know this,
    but they try to make theory as reliable a guide to
    practice as possible.
    </p>
    <p>One of the most important examples of the theoretician's successes
    is asymptotic notation --
    more commonly referred to as a big-O notation.
    The term "asymptotic notation"
    emphasizes its most dangerous aspect
    from a practical point of view:
    Asymptotic notation assumes
    that the behavior of most interest
    is the behavior for arbitrarily large inputs.
    Practical inputs can be very large but,
    by definition,
    they are never arbitrarily large.
    Results in asymptotic terms
    might be what is called "galactic" --
    they might have
    relevance only in situations which cannot possibly occur in practice.
    </p>
    <p>
    Fortunately for computer science,
    asymptotic results usually are
    not "galactic".
    Most often asymptotic results are not only
    relevant to practice --
    they are extremely relevant.
    Wikipedia pages for algorithms put
    the asymptotic complexities in special displays,
    and these displays are one of the first 
    things that some practitioners look at.
    </p>
    <h2>Bracketing</h2>
    <p>Since coming up with a theoretical model that is equivalent
    to "practical" is impossible,
    theoreticians often work like artillerists.
    Artillerists often deliberately overshoot and undershoot,
    before they "fire for effect".
    "Bracketing" their target in this way has disadvantages --
    it reduces the element of surprise,
    and can even allow the enemy to get their counter-fire in first.
    But, nasty as these consequences could be,
    the advantage in accuracy is usually held to outweigh them.
    </p>
    <p>The practice of theoretical computer science is 
    less risky,
    which makes "bracketing" a very attractive approach to
    tricky problems.
    Theoreticians often
    try to "bracket" practice between an "undershoot"
    and an "overshoot".
    The undershoots are models simple and efficient enough to be practical,
    but too weak to capture all the needs of practice.
    The overshoots are models which capture everything
    a practitioner needs,
    but are too complicated and/or too resource-intensive
    for practice.
    <p>The P vs. NP problem is an active example of a bracketing technique.
    You will sometimes read that
    the P/NP boundary is expected to be 
    that between practical and impractical,
    but this is an extreme simplification.
    P includes complexities like <tt>O(n^1000000)</tt>,
    where the complexity for even <tt>n == 2</tt> is
    a nunber which, in decimal form,
    fills several pages.
    Modulo bold advances in quantum computing,
    I cannot imagine that <tt>O(n^1000000)</tt> will ever be
    practical.
    And you can make the complexities even harder
    than <tt>O(n^1000000)</tt>
    without ever reaching P-hard.
    </p>
    <p>
    So P-hard is beyond any reasonable definition of "practical" --
    it is an "overshoot".
    But the P vs. NP question is almost certainly very relevant to what is "practical".
    Resolving the P vs. NP question is likely
    to be an important or even necessary step.
    It is a mystery that such a seemingly obvious
    question has resisted the best efforts of the theoreticians
    for so long,
    and the solution of P vs. NP is likely
    to bring
    new insights
    into asymptotic complexity.
    </p>
    <h2>Bracketing practical parsing</h2>
    <p>When Knuth published his 1965,
    "practical parsing" was already bracketed.
    On the overshoot side, Irons had already published a parser for
    context-free grammars.
    Worst case, this ran in exponential time,
    and it was, and remains, expected that general context-free parsing
    was not going to be practical.<footnote>
    The best lower bound for context-free parsing is still
    <tt>O(n)</tt>.
    So it is even possible that there is a practical
    linear-time general context-free
    parser.
    But its discovery would be a big surprise.
    </footnote>
    </p>
    <p>On the undershoot side,
    there were regular expressions and recursive descent.
    Regular expressions are fast and very practical,
    but parse a very limited set of grammars.
    Recursive descent is also fast and,
    since it parses a larger set of grammars,
    was the closest undershoot.
    </p>
    <h2>Mistake 1: The misdefinition of "language"</h2>
    <p>In curry respect from the behaviourists,
    American linguistics for many years banned any reference
    to meaning.
    Behaviorists looked down on
    hypothesized mental states as not worthy of "science",
    and it's hard to have a theory of meaning
    without conjectures about mental states.
    Without mental states,
    language was just a set of strings, or utterances.
    So American linguistics dutifully
    defined a "language" as a "set of strings".
    </p>
    <p>After a brief half-nod to this tradition,
    Noam Chomsky restored sanity to linguistics.
    But it was too late for computer science.
    Automata theory adopted the semantics-free definition.
    In 1965, Knuth inherited a lot of prior work,
    but almost all of it ignored,
    not just meaning or semantics,
    but even syntax and structure.
    </p>
    <h2>Language extension versus language intension</h2>
    <p>Knuth, of course, wanted to make contact with prior art.
    The definition he had inherited seemed to work well enough
    and Knuth's 1965 defines a language as a set of strings.
    Most subsequent work has refused to breach this tradition.
    </p>
    <p>In most people's idea of what a language is,
    the utterances/strings mean something --
    you cannot take just
    any set of meaningless strings and call it a language.
    So the parsing theorists and everybody else had
    two different definitions of language.
    </p>
    <p>But parsing theory also hoped to produce results relevant
    to practice,
    and few people are interested in recognizing meaningless strings --
    almost everybody who parses is interested in (at a minimum)
    finding some kind of structure in what they parse,
    in order to do something with the result of the parse.
    So parsing theorists ended up using the word in one
    sense, but suggesting results in another sense.
    As I will show,
    the result was a decades-long detour.
    </p>
    <p>
    At this point both senses of the word "language"
    have gotten entrenched in parsing theory so,
    instead of making up a new terminology,
    I will borrow a distinction from linguistics
    and speak of
    <b>the extension of a language</b>
    and 
    <b>the intension of a language</b>.
    The extension of a language is the Bloomfieldian defintion --
    the set of utterances/strings in the language.
    The intension of a language, for our purposes here,
    can be regarded as its BNF grammar.
    Each language intension will have (if it is well-defined)
    exactly one extension.
    But multiple language intensions can have the same extension.
    </p>
    <h2>Red Herring 1: The stack machine model is natural boundary</h2>
    <p>Again, Knuth, followed prior art,
    and used the term language in its extensional sense,
    as his audience expected.
    </p>
    <p>The computational model of context-free grammars 
    is non-deterministic stack machines -- stack machines which
    can "fork" themselves into multiple stack machines running
    at the same time.
    Of course, real-life computer cannot "fork" themselves,
    which reinforced the belief that context-free parsing is
    an "overshoot".
    </p>
    <p>LR-parsing corresponds exactly to the deterministic stack
    machines,
    which suggested that it was as close to a
    "direct hit" as theory was likely to get.
    It also strongly suggested that stack parsing was a "natural"
    way to characterize practical parsing,
    and therefore that stack-based algorithms would be
    optimal.
    [ This is reinforced when LR turns out to be an "overshoot". ]
    </p>
    <h2>Red Herring 2: LR parsers are not good at LR grammars</h2>
    <p>A second red herring led to the mis-bracketing of practical
    parsing.
    Having seemingly established that LR-parsing is a natural boundary
    in the hierarchy of languages,
    Knuth discovered that general LR-parsers were very far from practical.
    LR parsing goes out to LR(k) for arbitrary <tt>k</tt>,
    but even <tt>LR(1)</tt> parsing was impractical in 1965 --
    in fact, it is rare in practical use today.
    As the <tt>k</tt> in
    <tt>LR(k)></tt> grows, the size of the tables grows exponentially,
    while the value of the additional lookahead rapidly diminishes.
    It is not likely that
    <tt>LR(2)</tt> parsing will ever see much practical use,
    never mind <tt>LR(k) : k &gt; 2</tt>.
    From this it was concluded that LR-parsing is an overshoot.
    </p>
    <h2>Summary</h2>
    <ul>
    <li>Red Herring: All practical parsers as of 1965 are stack-based
    and deterministic.</li>
    <li>Red Herring: The language extensions that LR-parsers recognize
    are same as the language extensions that
    deterministic stack machines recognize.</li>
    <li>Red Herring: The non-deterministic stack machines recognize
    the context-free language extensions.</li>
    <li>Mistake: LR language extensions are a good proxy for
    language intensions.
    </ul>
    <p>
    From the above, the theoreticians concluded that
    the LR-parsers were very likely to be either the practical equivalent
    of context-free, or very close to it.
    </p>
    <p>So far the reasoning has gone astray,
    but not disastrously so.
    The whole point of bracketing, after all,
    is that it allows you to correct.
    The next red herring, however, resulted in
    parsing theory going on a decades-long
    wrong turn.
    </p>
    </ul>
    <li>Red herring: LR(k)-parsers very rapidly become impractical,
    almost certainly for <tt>k</tt> greater than 1,
    and probably for <tt>k</tt> equal to 1.</li>
    </ul>
    <p>
    Based on this, parsing theorists concluded that LR-parsing
    is an overshoot,
    when in fact it is an undershoot,
    and in practice a very large one.
    And, if you mistake an undershoot for an overshoot,
    your bracketing no longer works.
    </p>
    <h2>The Wrong Turn</h2>
    <p>
    From all this,
    parsing theorists concluded that
    <ul>
    <li>LR-parsing is a good approximation to practical parsing -- it brackets
    it closely.</li>
    <li>LR-parsing is an overshoot.</li>
    <li>A subset of LR-parsing will be the solution to the parsing problem.</li>
    </ul>
    <h2>Signs of trouble ignored</h2>
    <p>There were, at least with hindsight, clear signs
    that LR extensions were not a good proxy for LR grammars.
    LR grammars form a hierarchy --
    for every <tt>k</tt>, there is an LR grammar which
    is <tt>LR(k)</tt>, but which is not
    is <tt>LR(k+1)</tt>.
    But, when you look at extensions the hierarchy immediately
    collapses almost totally --
    every <tt>LR(k)</tt> language is also an 
    an <tt>LR(1)</tt>,
    as long as <tt>k &#2265; 1</tt>.
    Only <tt>LR(0)</tt>
    remains distinct.
    </p>
    <p>But it gets worse.
    In most practical applications,
    you can add an end-of-input marker to a grammar.
    If you do this the LR extension hierarchy collapses all the way
    down to zero --
    every <tt>LR(k)</tt> language extension is also an 
    <tt>LR(0)</tt> language extension.
    </p>
    <p>In short, it seems that,
    as an a proxy for LR grammars,
    LR language extension are likely to be completely worthless.
    </p>
    <h2>Why didn't Knuth see the problem?</h2>
    <p>Why didn't Knuth see the problem?
    Knuth certainly noted the strange behavior of the LR hierarchy
    in extensional terms -- he discovered it,
    and the amount of complicated mathematics suggests he spent
    a great deal of time on working it out.
    </p>
    <p>But Knuth did not see the behavior, strange as it was,
    as a potential problem.<footnote>
    Or at least Knuth does not mention any potential problems.
    And
    Knuth would have been well aware of the inferences
    about language intensions
    which would
    be drawn from his language extension results,
    </footnote>
    Why?
    </p>
    <p>So why does Knuth
    "pun" intension and extension?
    Well, first off, he had no real choice if he
    wanted to compare
    stack machines and LR-parsers.
    They
    had incomparable intensions,
    so the only way to establish that stack machines
    were equivalent to LR-parsers was via extensions.
    </p>
    <p>
    But why did
    Knuth expect to get away with punning
    intension and extension,
    even in the face of some very unsettling results?
    Here, the answer is very simple --
    "punning" had always worked before.
    </p>
    <p>
    Regular expressions are easily turned into parsers<footnote>
    For example,
    regular expressions can be extended with "captures".
    Captures cannot handle recursion, but neither can regular expressions,
    so captures are usually sufficient to provide all structure
    an application wants.
    </footnote>,
    so the language extension of a regular grammar is an adequate approximation
    to its intension.
    Context-free recognition has the same complexity,
    and in practice uses the same algorithms,
    as context-free parsing,
    so here again,
    language extension is a good approximation
    of language intension.
    </p>
    <p>
    And the LL languages follow a strict hierarchy --
    for every <tt>k</tt>,
    <tt>LL(k)</tt> is a proper subset of <tt>LL(k+1)</tt>.
    This fact forces LL grammars to follow the same
    hierarchy<footnote>
    This is because
    every LL(k) intension (grammar) must have an LL(k) extension.
    </footnote>.
    So, when studying complexity, 
    LL language extensions are an excellent proxy for
    LL grammars.
    </p>
    <p>
    Based on past experience,
    Knuth had every reason to believe
    he could use language extensions as a proxy
    for grammars,
    and recognizers as a proxy
    for parsers,
    and the result would be
    a theory that was reliable
    approximation to practice.
    </p>
    <h2>Outtakes</h2>
    <p>
    I say "unfortunately" because recognizing that a string belongs
    to a set is not the same as parsing it.
    It is not even all that close.
    As one example, it is easy to recognize that a string like
    "<tt>2*3+4^5-7/8</tt>" represents
    an arithmetic expression.
    It is a lot harder to figure out the structure
    of that arithmetic expression,
    using the traditional associativity
    and precedence of the operators.
    And it is that <b>structure</b> that you have to recognize,
    if you are going to evaluate the expression.
    </p>
    <h2>Aftermath</h2>
    <p>As stated above,
    1965 hardware limits led practitions to suspect that stack machines
    model were an upper limit to the practical.
    The theoreticians took this into account.
    Of course, the logic can get dangerously circular
    if theoreticians take practice as too much of a guide to
    what is possible.
    The job of theory,
    after all, to guide practice,
    not merely to record it.
    </p>
    <p>In 1965, the theoreticians gave a lot of weight
    to the evidence from the world of practice,
    but probably not undue weight.
    Going forward, it was a different story.
    Practitioners saw no reason to question the theoretician's
    conclusions,
    and theoreticians, seeing that beyond-LR methods did not
    come into use in the world of practice,
    felt no need to question their conclusions either.
    </p>
    <h2>Comments, etc.</h2>
    <p>
      I encourage
      those who want to know more about the story of Parsing Theory
      to look at my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
        Parsing: a timeline 3.0</a>.
      In particular,
      "Timeline 3.0" tells the story of the search for a good
      LR(k) subclass,
      and what happened afterwards.
    </p>
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
