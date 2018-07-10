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
      The question really requires two separate answers:
    </p><ul>
      <li>"Why do practitioners accept the current state of the art as the solution?" and
      </li><li>"Why do the theoreticians accept the current state of the art as the solution?"
      </li></ul>
    <p>
    </p><p>In one sense, the answer to both questions is the same --
      because of the consensus created by Knuth's 1965 paper
      "On the translation of languages from left to right".
      In
      <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">a previous post</a>,
      I looked at Knuth 1965
      and I answered the practitioner question in detail.
      But, for the sake of brevity,
      I answered the question about the theoreticians in outline.
      This post expands on that outline.
    </p>
    <h2>The Practitioners</h2>
    <p>
      To summarize, in 1965,
      <b>practitioners</b>
      accepted the parsing problem as solved
      for the following reasons.
    </p>
    <ul>
      <li>In 1965, every practical parser was stack-driven.</li>
      <li>As of 1965, stacks themselves were quite leading edge.
        As recently as 1961,
        a leading edge article<footnote>
          Oettinger, Anthony. "Automatic Syntactic Analysis and the Pushdown
          Store",
          <cite>Proceedings of Symposia in Applied Mathematics</cite>,
          Volume 12,
          American Mathematical Society, 1961.
          Oettinger describes "push" and "pop"
          stack operations in "Iversion notation" -- what
          later became APL.
          See the discussion of Oettinger in
          my
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
        practitioners that
        <tt>LR</tt>-parsing was either state-of-the-art
        or beyond,
        so making more agressive use of hardware
        would be futile.
      </li>
    </ul>
    <h2>What about the theorists?</h2>
    <p>The practitioners of 1965, then,
      were quite reasonable in feeling that
      <tt>LR</tt>-parsing was as good as anything they were likely to be able
      to implement any time soon.
      And they were being told by the theorists that,
      in fact,
      it never would get any better --
      there were theoretical limits on parsers that faster
      hardware could not overcome.
    </p>
    <p>We now know that the theorists were wrong --
      there are non-<tt>LR</tt>
      parsers which are better than the
      <tt>LR</tt>
      parsers are at
      <tt>LR</tt>
      grammars.
      What made the theorists go astray?
    </p>
    <h2>How theorists work</h2>
    <p>As the epigraph for this post reminds us,
      theorists who hope to guide practitioners have to confront a big problem --
      theory is practice only in theory.
      Theoreticians
      (or at least the better ones, like Knuth)
      know this,
      but they try to make theory as reliable a guide to
      practice as possible.
    </p>
    <p>One of the most important examples of the theoretician's successes
      is asymptotic notation, which we owe to Knuth<footnote>
        Knuth did not invent asymptotic notation --
        it comes from calculus --
        but he introduced it to computer science
        and motivated its use.
      </footnote>.
      Asymptotic notation is
      more commonly referred to as big-O notation.
      The term "asymptotic notation"
      emphasizes its most dangerous aspect
      from a practical point of view:
      Asymptotic notation assumes
      that the behavior of most interest
      is the behavior for arbitrarily large inputs.
    </p>
    <p>
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
      but which are too complicated and/or too resource-intensive
      for practice.
    </p><p>The P vs. NP problem is an active example of a bracketing technique.
      You will sometimes read that
      the P/NP boundary is expected to be
      that between practical and impractical,
      but this is an extreme simplification.
      P includes complexities like
      <tt>O(n^1000000)</tt>,
      where the complexity for even
      <tt>n == 2</tt>
      is
      a nunber which, in decimal form,
      fills many pages.
      Modulo bold advances in quantum computing,
      I cannot imagine that
      <tt>O(n^1000000)</tt>
      will ever be
      practical.
      And you can make the complexities much harder
      than
      <tt>O(n^1000000)</tt>
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
    <p>To curry respect from the behaviourists,
      American linguistics for many years banned any reference
      to meaning.
      Behaviorists looked down on
      hypothesized mental states as not worthy of "science",
      and it's hard to have a theory of meaning
      without conjectures about mental states.
      Without mental states,
      language was just a set of utterances.
      So in 1926 the linguist Leonard Bloomfield
      dutifully
      defined a "language" as a set of "utterances"
      (for our purposes, "strings"),
      and through the 30s and 40s most American
      linguists followed him.
    </p>
    <p>After a brief nod to this tradition,
      Noam Chomsky restored sanity to linguistics.
      But it was too late for computer science.
      Automata theory adopted the semantics-free definition.
      In 1965, Knuth inherited a lot of prior work,
      almost all of which ignored,
      not just meaning or semantics,
      but even syntax and structure.<footnote>
        In
        <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/chomsky_1956.html">
          another blog post</a>,
        I talk about the use of the word
        "language" in parsing theory
        in much more detail.
      </footnote>
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
      Parsing theorists ended up using the word "language" in one
      sense, but implying that results they found worked
      for the word "language" in the usual sense.
    </p>
    <p>
      At this point both senses of the word "language"
      have gotten entrenched in parsing theory.
      Instead of making up a new terminology for this blog post,
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
    <h2>Red Herring 1: The stack machine model as a natural boundary</h2>
    <p>The temptation to use language extensions as
      a proxy for
      <tt>LR</tt>-grammars must have been overwhelming.
      It turns out that the language extension of
      deterministic stack machines
      is
      <b>exactly</b>
      that of the
      <tt>LR</tt>
      grammars.
      Further,
      the language extension of the context-free grammars is
      exactly that of the non-deterministic stack machines.
      (Non-deterministic stack machines are
      stack machines which can "fork" new instances of themselves on the fly.)
    </p>
    <p>
      If you take language extensions as the proxy for grammars,
      things fall into place very neatly:
      the
      <tt>LR</tt>-parsers are the deterministic subset of the
      context-free parsers.
      And "deterministic" seemed like a very good approximation
      of practical.
      Certainly non-deterministic parsing is probably not practical.
      And the best practical parsers in 1965 were
      deterministic stack parsers.
    </p><p>
      Viewed this way,
      <tt>LR</tt>-parsing looked like the equivalent
      of practical parsing.
      It was a "direct hit",
      or as close to a exact equivalent of practical parsing
      as theory was going to get.
    </p>
    <p>As we shall see,
      with this red herring,
      the reasoning went astray.
      But disaster was not inevitable.
      The whole point of bracketing, after all,
      is that it allows you to correct errors.
      Another red herring, however, resulted in
      parsing theory going on a decades-long
      wrong turn.
    </p>
    <h2>Red Herring 2:
      <tt>LR</tt>
      parsers are not good at
      <tt>LR</tt>
      grammars</h2>
    <p>The second red herring led to the mis-bracketing of practical
      parsing.
      Having seemingly established that
      <tt>LR</tt>-parsing is a natural boundary
      in the hierarchy of languages,
      Knuth discovered that general
      <tt>LR</tt>-parsers were very far from practical.
      <tt>LR</tt>
      parsing goes out to
      <tt>LR(k)</tt>
      for arbitrary
      <tt>k</tt>,
      but even
      <tt>LR(1)</tt>
      parsing was impractical in 1965 --
      in fact, it is rare in practical use today.
      As the
      <tt>k</tt>
      in
      <tt>LR(k)</tt>
      grows, the size of the tables grows exponentially,
      while the value of the additional lookahead rapidly diminishes.
      It is not likely that
      <tt>LR(2)</tt>
      parsing will ever see much practical use,
      never mind
      <tt>LR(k)</tt> for any <tt>k</tt>
      greater than 2.
    </p>
    <p>
      From this it was concluded that
      <tt>LR</tt>-parsing is an overshoot.
      In reality,
      as Joop Leo was to show,
      it is an
      <b>undershoot</b>,
      and in practical terms a very large one.
      If you mistake an undershoot for an overshoot,
      bracketing no longer works,
      and you are not likely to hit your target.
    </p>
    <h2>The Wrong Turn</h2>
    <p>
      Summing up,
      parsing theorists concluded,
      based on the results of Knuth 1965,
      that
    </p><ul>
      <li>LR-parsing is a good approximation to practical parsing -- it brackets
        it closely.</li>
      <li>LR-parsing is an overshoot.</li>
      <li>A subset of
        <tt>LR</tt>-parsing will be the solution to the parsing problem.</li>
    </ul>
    <h2>Signs of trouble ignored</h2>
    <p>There were, in hindsight, clear signs
      that
      <tt>LR</tt>
      language extensions were not a good proxy for
      <tt>LR</tt>
      grammars.
      <tt>LR</tt>
      grammars form a hierarchy --
      for every
      <tt>k&#8805;0</tt>,
      there is an
      <tt>LR</tt>
      grammar which
      is
      <tt>LR(k+1)</tt>, but which is not
      <tt>LR(k)</tt>.
    </p>
    <p>
      But if you look at extensions
      instead of grammars,
      the hierarchy immediately
      collapses --
      every
      <tt>LR(k)</tt>
      language extension is also
      an
      <tt>LR(1)</tt>
      language extension,
      as long as
      <tt>k&#8805;1</tt>.
      Only
      <tt>LR(0)</tt>
      remains distinct.
    </p>
    <p>It gets worse.
      In most practical applications,
      you can add an end-of-input marker to a grammar.
      If you do this the
      <tt>LR</tt>
      extension hierarchy collapses totally --
      every
      <tt>LR(k)</tt>
      language extension is also an
      <tt>LR(0)</tt>
      language extension.
    </p>
    <p>In short, it seems that,
      as a proxy for
      <tt>LR</tt>
      grammars,
      <tt>LR</tt>
      language extensions are likely to be completely worthless.
    </p>
    <h2>Why didn't Knuth see the problem?</h2>
    <p>Why didn't Knuth see the problem?
      Knuth certainly noted the strange behavior of the
      <tt>LR</tt>
      hierarchy
      in extensional terms -- he discovered it,
      and devoted several dense pages of his 1965 to laying
      out the complicated mathematics involved.
    </p>
    <p>
      So why did
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
        so captures are usually sufficient to provide all the structure
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
      And the
      <tt>LL</tt>
      language extensions follow a strict hierarchy --
      for every
      <tt>k&#8805;0</tt>,
      <tt>LL(k+1)</tt>
      is a proper subset of
      <tt>LL(k)</tt>.
      This fact forces
      <tt>LL</tt>
      grammars to follow the same
      hierarchy<footnote>
        The discussion of the
        <tt>LL(k)</tt>
        hierarchy is in a sense anachronistic --
        the
        <tt>LL(k)</tt>
        hierachy was not studied until after 1965.
        But Knuth certainly was aware of recursive descent,
        and it seems reasonable to suppose that,
        even in 1965,
        he had a sense of what
        the
        <tt>LL</tt>
        hierarchy would look like.
      </footnote>.
      So, when studying complexity,
      <tt>LL</tt>
      language extensions are an excellent proxy for
      <tt>LL</tt>
      grammars.
    </p>
    <p>
      Based on past experience,
      Knuth had reason to believe
      he could use language extensions as a proxy
      for grammars,
      and that the result would be
      a theory that was a reliable
      guide to practice.
    </p>
    <h2>Aftermath</h2>
    <p>In
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
        my timeline of parsing</a>,
      I describe what happened next.
      Briefly,
      theory focused on finding a useful subset of
      <tt>LR(1)</tt>.
      One,
      <tt>LALR</tt>, became the favorite and
      the basis of the
      <tt>yacc</tt>
      and
      <tt>bison</tt>
      tools.
    </p>
    <p>
      Research into parsing of supersets of
      <tt>LR</tt>
      became rare.
      The theorists were convinced the
      <tt>LR</tt>
      parsing
      was the solution.
      These were so convinced that when,
      in 1991, Joop Leo discovered a practical way to
      parse an
      <tt>LR</tt> superset,
      the result went unimplemented for decades.
    </p>
    <p>In 1965, the theoreticians gave a lot of weight
      to the evidence from the world of practice,
      but probably not undue weight.
      Going forward, it was a different story.
    </p>
    <p>
      Leo had,
      in essence,
      disproved the implied conjecture of Knuth 1965.
      But the question is
      not an explicit mathematical question,
      like that of P vs. NP.
      It is a slipprier one -- capturing practice.
      Practitioners left it to the theoreticians to keep up with
      the literature.
      But theoreticians, as long as
      <tt>LR</tt>-superset methods did not
      come into use in the world of practice,
      felt no need to revisit their conclusions.
    </p>
    <h2>Comments, etc.</h2>
    <p>
      I encourage
      those who want to know more about the story of Parsing Theory
      to look at my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
        Parsing: a timeline 3.0</a>.
      To learn about Marpa,
      my Earley/Leo-based parsing project,
      there is the
      <a href="http://savage.net.au/Marpa.html">semi-official web site, maintained by Ron Savage</a>.
      The official, but more limited, Marpa website
      <a href="http://jeffreykegler.github.io/Marpa-web-site/">is my personal one</a>.
      Comments on this post can be made in
      <a href="http://groups.google.com/group/marpa-parser">
        Marpa's Google group</a>,
      or on our IRC channel:
      <tt>#marpa</tt> at <tt>freenode.net</tt>.
    </p>
    <comment>FOOTNOTES HERE</comment>
  </body>
</html>
