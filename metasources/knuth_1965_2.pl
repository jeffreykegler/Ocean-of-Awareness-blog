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
    <h2>Reason 1: Misdefiniton of language</h2>
    <h2>Reason 2: Conflation of linear with deterministic</h2>
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
