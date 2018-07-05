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
      This kind of "computational mysticism" has taken a beating, but
      survives in one last stronghold -- parsing theory.
    </p><p>
      In a previous post I asked "Why is parsing considered solved?"
      If the state of the art of computer parsing is taken as anything close to its ultimate solution,
      then the human brain has some
      strange power that makes it much better at parsing than computers can be.
      It is very unlikely this would certainly be accepted as an explanation
      of any other problem,
      which raises the question:
      Why is it accepted for parsing theory.<footnote>
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
        I think it is best to be extremely reluctant to accept
        human exceptionalism.
      </footnote>
    </p>
    <p>
      I addressed this question in
      <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">a previous post</a>.
      The question of why
      <b>practitioners</b>
      accepted the problem as solved
      in 1965
      has a straightforward answer:
    </p><ul>
      <li>In 1965, every practical parser was stack-driven.<footnote>
          CYK?
        </footnote></li>
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
      In 1965, any more complicated algorithm was very likely to be unuseable
      in practice.
      </li>
      <li>And last, but not least, the theoreticians assured the
      practitioners that LR-parsing was either state-of-the-art
      or beyond,
      so that stretching the capabilities of the hardware would
      have been pointless.
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
    LR parsers are at their own grammars.
    What made the theorists go astray?
    </p>
    <h2>How theorists work</h2>
    <p>In
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/knuth_1965.html">
    a previous post</a>,
    I briefly mentioned the factors behind theory's wrong turn.
    Here I will put them more in context.
    </p>
    <p>As the epigraph for this post reminds us,
    theorists who hope to guide practitioners have to confront a big problem --
    theory is not practice except in theory.
    Theoreticians (at least some) know this,
    but they try to make theory as good a guide as possible.
    Big-O notation assumes
    that the most dangerous of these is that the behavior of most interest
    is that for arbitrarily large inputs.
    Practical inputs, of course,
    can be very large, but they are never arbitrarily large.
    This suggests that 
    big-O complexity measures might be "galactic" --
    relevant only to situations which cannot occur in practice.
    </p>
    <p>
    Despite the potential problem,
    big-O analysis rarely goes "galactic".
    It is almost always relevant to practice --
    usually it is extremely relevant.
    As a result,
    The big-O complexities are one of the first 
    things many practitioners want to know about a new
    algorithm,
    because while the practical programming world is
    never the world of big-O,
    in most cases it looks an awful lot like it.
    </p>
    <p>Since coming up with a theoretical model that is equivalent
    to "practical" is impossible,
    theoreticians often work like artillerists.
    They try to "bracket" practice between an impractical model,
    on one side,
    and a model too simple to capture practice on the other side.
    </p>
    <h2>Reason 1: Conflation of linear with deterministic</h2>
    <h2>Reason 2: Misdefinition of language</h2>
    <p>A very persuasive reason to believe LR was the "right"
    theoretical equivalent of practical was its naturalness --
    or what was mistakenly seem as its naturalness.
    It turns out that, unfortunately,
    deterministic stack machines
    and LR-parsers recognize exactly the same sets of strings.
    </p>
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
    <p>The distinction between parsing and recognition was
    not lost on most of Knuth's readers --
    it certainly was not lost on Knuth.
    Nonetheless a good deal of the most complicated mathematics
    in Knuth 1965 is devoted showing the equivalence of LR
    and deterministic stack machines
    <b>in terms of sets of strings</b>.
    </p>
    <p>This is because of a detour by American linguistics --
    in order to satisfy the behaviourists, who looked down
    on descriptions in terms of hypothesized mental states,
    Unbelieveably,
    American linguistics for many years banned any reference
    to meaning.
    "Sets of strings" were what they had left.
    So they defined a "language" as a "set of strings".
    </p>
    <p>Noam Chomsky restored sanity to linguistics,
    but it was too late.
    Automata theory adopted the semantics-free definition,
    and the prior work that Knuth inherited ignored
    not just questions of meaning or semantics,
    but even of syntax or structure.
    Knuth, of course, wanted to make contact with
    the prior art.
    </p>
    <p>Knuth could not prove that LR-parsers
    to deterministic stack machines as parsers,
    because deterministic stack machine did not parse.
    Deterministic stack machines only recognized languages.
    </p>
    <p>LR-parsers, as a by-product of parsing a string, could
    be seen as "recognizing" that string as belonging to a set.
    If an LR-parser successfully parsed a string,
    it belonged to the set.
    If an LR-parser failed to produce a parse for a string,
    that string did not belong to the set.
    </p>
    <p>So Knuth proved, as he was forced to,
    the equivalence of LR-parsers and deterministic stack machines
    in terms of sets of strings.
    Previously successful models of computation had tended
    to correspond (more or less) neatly
    to classes of languages,
    and the LR languages and deterministic stack machine
    model of computing feel nicely into a new slot,
    one which seemed like a very nice overshoot of
    the "practical" model of computation for parsing.
    </p>
    <p>But, even in Knuth's paper, there are clear indications
    that things were not so neat.
    The issue was not classifying string-sets -- it was parsing.
    The other models of computation obscured this issue.
    Regular expressions are so simple that parsing can be ignored
    or hacked in at a rudimentary level
    Turing machines (the computational model for the recursively enumerable languages)
    are so general they far overshoot the target for practical parsing,
    but they are so powerful that parsers fall out of them easily as a side effect.
    And context-free grammars [...]
    </p>
    <h2>Bracketing</h2>
    <p>Of course, most readers of Knuth's paper were quite aware that
    the extension of a grammar
    <footnote>Define extension and intension.
    </footnote>
    are not the same as the grammar itself (its "intension").
    Certainly Knuth knew this.
    So why does "pun" the two and expect to get away with it?
    </p>
    <p>The answer is simple -- it had always worked before.
    In particular, when Knuth is writing the "practical grammars"
    had already been bracketed --
    Knuth was trying to narrow
    the bracketing.
    Regular expressions were the undershoot, and they were
    so simple that, in practice
    a parser could conveniently be hacked onto a recognizer.
    <footnote>
    For example,
    regular expressions can be extended with "captures".
    Captures cannot handle recursion, but neither can regular expressions,
    so captures are usually sufficient to provide all structure
    an application wants.
    </footnote>.
    The overshoot, which Knuth was attempting to replace,
    was the context-free grammars,
    and the most practical recognizer for these produced
    a parse as a by-product.<footnote>
    Refer to Pingali&Bilardi here.
    </footnote>
    So,
    since for stack machines Knuth had only extensions to work with,
    and since results for grammar extensions had always proved applicable
    to grammar intensions,
    Knuth has reason to believe he was using
    a theory that was reliable
    approximation to practice.
    </p>
    <h2>Reason 3: The evidence from the practitioners</h2>
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
