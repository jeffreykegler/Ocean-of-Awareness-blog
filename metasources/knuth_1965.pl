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
Why is parsing considered solved?
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <p>It is often said that parsing is a "solved problem".
      Given the level of frustration with the state of the art,
      the underuse of the very powerful technique of
      Language-Oriented Programming due to problematic tools<footnote>
        The well-known
        <a href="https://en.wikipedia.org/wiki/Design_Patterns">
          <cite>Design Patterns</cite>
          book</a>
        (aka "the Gang of 4 book")
        has a section on this.
        The Gang of 4
        call Language-Oriented Programming
        their "Interpreter pattern".
        That section amply illustrates the main obstacle to use
        of the pattern -- lack of adequate parsing tools.
        I talk more about this in my two blog posts on
        the Interpreter pattern:
        <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2013/03/bnf_to_ast.html">
          BNF to AST</a>
        and
        <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2013/03/interpreter.html">
          The Interpreter Design Pattern</a>.
      </footnote>,
      and the vast superiority of human parsing ability
      over computers,
      this requires explanation.
    </p>
    <p>
      On what grounds would someone say that parsing is "solved"?
      To understand this,
      we need to look at the history of Parsing Theory.<footnote>
        This post takes the form of a timeline, and
        is intended to be incorporated in my
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
          Parsing: a timeline</a>.
        The earlier entires in this post borrow heavily from
        <a href="http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2018/05/chomsky_1956.html">
          a previous blog post</a>.
      </footnote>
      In fact, we'll have to start decades before computer Parsing Theory
      exists,
      with a now nearly-extinct school of linguistics,
      and its desire to put the field on strictly
      scientific basis.
    </p>
    <h2>1929: Bloomfield redefines "language"</h2>
    <p>In 1929 Leonard Bloomfield,
      as part of his effort to create a linguistics that
      would be taken seriously as a science,
      published his "Postulates".<footnote>
        Bloomfield, Leonard,
        "A set of Postulates
        for the Science of Language",
        <cite>Language</cite>, Vol. 2, No. 3 (Sep., 1926), pp. 153-164.
      </footnote>
      The "Postulates" include his definition of language:
    </p><blockquote>
      The totality of utterances that can be made in a speech
      community is the
      <b>language</b>
      of that speech-community.<footnote>
        Bloomfield 1926, definition 4 on p. 154.
      </footnote>
    </blockquote><p>
      There is no reference in this definition to the usual view,
      that the utterances of a language "mean" something.
      This omission is not accidental:
    </p><blockquote>
      The statement of meanings is therefore the weak point in
      language-study, and will remain so until human knowledge
      advances very far beyond its present state. In practice, we define the
      meaning of a linguistic form, wherever we can, in terms of some
      other science.<footnote>
        Bloomfield, Leonard.
        <cite>Language</cite>.
        Holt, Rinehart and Winston, 1933, p. 140.
      </footnote>
    </blockquote><p>
      Bloomfield is passing the buck,
      because the behaviorist science of his time rejects
      any claims about mental states as
      unverifiable statements -- essentially,
      as claims to be able to read minds.
      "Hard" sciences like physics, chemistry and even
      biology avoid dealing with unverifiable mental states.
      Bloomfield and the behaviorists want to make the methods of linguistics
      as close to hard science as possible.
    </p>
    <p>
      Draconian as Bloomfield's exclusion of meaning is,
      it is a big success.
      Known as structural linguistics,
      Bloomfield's approach dominates lingustics for
      the next couple of decades.
    </p>
    <h2>1955: Noam Chomsky graduates</h2>
    <p>
      Noam Chomsky earns his PhD at the University of Pennsylvania.
      His teacher, Zelig Harris, is a prominent Bloomfieldian,
      and Chomsky's early work is thought to be in the Bloomfield school.<footnote>
        Harris, Randy Allen,
        <cite>The Linguistics Wars</cite>,
        Oxford University Press, 1993,
        pp 31-34, p. 37.
      </footnote>
      Chomsky becomes a professor at MIT.
      MIT does not have a linguistics department,
      and Chomsky is free to teach his own approach to the subject.
    </p>
    <h2>The term "language" as of 1956</h2>
    <p>Chomsky publishes his "Three models" paper,
      one of the most important papers of all time.
      His definition of language uses the terminology
      of set theory:
    </p><blockquote>
      By a language then, we shall mean a set (finite or infinite) of
      sentences, each of finite length, all constructed from a finite
      alphabet of symbols.<footnote>
        The quote is on p. 114 of
        Chomsky, Noam.
        "Three models for the description of language."
        <cite>IRE Transactions on information theory</cite>,
        vol. 2, issue 3, September 1956, pp. 113-124.
        In case there is any doubt Chomsky's "strings"
        are Bloomfield's utterances,
        Chomsky also calls his strings,
        "utterances".
        For example in Chomsky, Noam,
        <cite>Syntactic Structures</cite>,
        2nd ed.,
        Mouton de Gruyter, 2002, on p. 15:
        "Any grammar of a language will project the finite and somewhat accidental
        corpus of observed utterances to a set (presumably infinite)
        of grammatical utterances."
      </footnote>
    </blockquote>
    <p>
      This definition is pure Bloomfield in substance,
      but signs of departure from the behaviorist orthodoxy are
      apparent in "Three Models" --
      Chomsky is quite willing to talk about what sentences mean,
      when it serves his purposes.
      For a utterance with multiple meanings,
      Chomsky's new model produces multiple syntactic derivations.
      Each of these syntactic derivations
      "looks" like the natural representation
      of one of the meanings.
      Chomsky points out that the insight into semantics
      that his new model provides is a very
      desirable property to have.<footnote>
        Chomsky 1956, p. 118, p. 123.
      </footnote>
    </p>
    <h2>1959: Chomsky reviews Skinner</h2>
    <p>In 1959, Chomsky reviews a book by B.F. Skinner's on linguistics.<footnote>
        Chomsky, Noam.
        “A Review of B. F. Skinner’s Verbal Behavior”.
        <cite>Language</cite>,
        Volume 35, No. 1, 1959, 26-58.
        <a href="https://chomsky.info/1967____/">
          https://chomsky.info/1967____/</a>
        accessed on 3 June 2018.
      </footnote>
      Skinner is the most prominent behaviorist of the time.
    </p>
    <p>
      Chomsky's review removes all doubt about where he stands
      on behaviorism
      or on the relevance of linguistics to the study of meaning.<footnote>
        See in particular, Section IX of Chomsky 1959.
      </footnote>
      His review galvanizes the opposition to behaviorism, and
      Chomsky establishes himself as behavorism's most
      prominent and effective critic.
    </p>
    <p>
      In later years,
      Chomsky will make it clear that he had had no intention
      of avoiding semantics:
    </p><blockquote>
      [...] it would be absurd to develop
      a general syntactic theory
      without assigning an absolutely
      crucial role to semantic considerations,
      since obviously the necessity to support
      semantic interpretation is one of the primary
      requirements
      that the structures
      generated by the syntactic component of a grammar
      must meet.<footnote>
        Chomsky, Noam.
        <cite>Topics in the Theory of Generative Grammar</cite>.
        De Gruyter, 1978, p. 20.
        (The quote occurs in footnote 7 starting on p. 19.)
      </footnote>
    </blockquote>
    <h2>1961: Oettinger discovers pushdown automata</h2>
    <p>
      While the stack itself goes back to Turing<footnote>
        Carpenter, Brian E., and Robert W. Doran.
        "The other Turing machine."
        <cite>The Computer Journal</cite>, vol. 20, issue 3, 1 January 1977, pp. 269-279.
      </footnote>,
      its significance for parsing becomes an object
      of interest in itself with
      Samuelson and Bauer's 1959 paper<footnote>
        Samelson, Klaus, and Friedrich L. Bauer. "Sequentielle formelübersetzung." it-Information Technology 1.1-4 (1959): 176-182.
      </footnote>.
      Mathematical study of stacks as models of computing begins with Anthony Oettinger's 1961 paper.<footnote>
        Oettinger, Anthony.
        "Automatic Syntactic Analysis and the Pushdown Store"
        <cite>Proceedings of Symposia in Applied Mathematics</cite>,
        Volume 12,
        American Mathematical Society, 1961.
      </footnote></p>
    <p>Oettinger 1961 is full of evidence that stacks
      (which he calls "pushdown stores") are still very new.
      For example,
      Oettinger does not use the terms "push" or "pop",
      but instead describes operations on his pushdown stores using
      a set of vector operations which will later form the basis
      of the APL language.
    </p>
    <p>Oettinger defines 4 languages.
      Oettinger's definitions all follow the behavorist model --
      they are sets of strings.<footnote>
        Oettinger 1961, p. 106.
      </footnote>
      Oettinger's pushdown stores
      will eventually be called
      deterministic pushdown automata (DPDA's) and
      become the basis of a model of language
      and the subject of a substantial literature,
      all of which will use the behaviorist definition
      of "language".
    </p>
    <p>
      Oettinger hopes that DPDA's
      will be an adequate basis for
      the study of both computer and
      natural language translation.
      (Oettinger's own field is Russian translation.)
      DPDA's soon prove totally inadequate
      for natural languages.
    </p>
    <p>
      But for dealing with computing languages,
      DPDA's will have a much longer life.
      As of 1961, all algorithms with acceptable speed are using
      stacks with various modifications.
    </p>
    <blockquote>
      The development of a theory of pushdown algorithms should
      hopefully lead to systematic techniques for generating
      algorithms satisfying given requirements to replace
      the ad hoc invention of each new algorithm.<footnote>
        Oettinger 1961, p. 127.
      </footnote>
    </blockquote>
    <p>
      The search for a comprehensive theory of
      stack-based parsing
      quickly becomes identified
      with the search for a theoretical basis for practical parsing.
    </p>
    <h2>1965: Knuth discovers LR(k)</h2>
    <p>Donald Knuth
      reports his new results on stack-based parsing.
      In a pivotal paper<footnote>
        Knuth, Donald E.
        "On the translation of languages from left to right."
        <cite>Information and Control</cite>, Volume 8, Issue 6, December 1965, pp. 607-639.
        <a href="https://ac.els-cdn.com/S0019995865904262/1-s2.0-S0019995865904262-main.pdf?_tid=dcf0f8a0-d312-475e-a559-be7714206374&acdnat=1524066529_64987973992d3a5fffc1b0908fe20b1d">
          https://ac.els-cdn.com/S0019995865904262/1-s2.0-S0019995865904262-main.pdf?_tid=dcf0f8a0-d312-475e-a559-be7714206374&acdnat=1524066529_64987973992d3a5fffc1b0908fe20b1d</a>, accessed 24 April 2018.
      </footnote>,
      Knuth sets out a theory that
      encompasses all the "tricks"<footnote>
        Knuth 1965, p. 607, in the abstract.
      </footnote>
      used for efficient parsing up to that time.
      With this Oettinger's hope for a theory
      to replace "ad hoc invention" is fulfilled.
      In an exhilarating (and exhausting) 39-page
      demonstration of mathematical virtuousity,
      Knuth shows that stack-based parsing is
      equivalent to a new and unexpected class of grammars.
      Knuth calls these LR(k), and provides a parsing algorithm for them.
    </p>
    <p>
      Knuth's new algorithm might be expected to be "the one to rule
      them all".
      Unfortunately, while deterministic and linear,
      it is not practical -- it requires huge tables well beyond
      the memory capabilities of the time.
    </p>
    <p>
      The impracticality of his LR(k) algorithm
      does not suggest to Knuth that the stack-based model
      is inappropriate as a model of practical parsing.
      Instead it suggests to him, and to the field,
      that the boundary of practical parsing lies in a subclass of the
      LR(k) grammars.
    </p>
    <p>
      To be sure,
      Knuth, in his program for further research<footnote>
        Knuth 1961, pp. 637-639.
      </footnote>,
      does suggests investigation of parsers for superclasses
      of LR(k).
      He even describes a new superclass of his own:
      LR(k,t), which is LR(k) with more aggressive lookahead.
      But he is clearly unenthusiastic about LR(k,t).<footnote>
        "Finally, we might mention another generalization of LR(k)"
        (Knuth 1965, p. 638); and
        "One might choose to call this left-to-right translation,
        although we had to back up a finite amount."
        (p. 639).
      </footnote>
      It is reasonable to suppose
      that Knuth is even more negative about
      the more general approaches that
      he does not bother to mention.<footnote>
        Knuth's skepticism of more general Chomskyan approaches
        is suggested by his own plans for his (not yet released) Chapter
        12 of the
        <cite>Art of Computer Programming</cite>,
        in which he planned to use pre-Chomskyan bottom-up methods. (See
        Knuth, Donald E., "The genesis of attribute grammars",
        <cite>Attribute Grammars and Their Applications</cite>,
        Springer, September 1990, p. 3.)
      </footnote>
    </p>
    <p>
      In any case, those reading Knuth's LR(k) paper focused almost
      exclusively on his suggestions for research within the stack-based
      model.
      These included grammar rewrites;
      streamlining of the LR(k) tables;
      and research into LR(k) subclasses.
      It is LR(k) subclassing that will receive the most attention.<footnote>
        The story of the research followup to Knuth's LR(k) paper is told
        in my
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
          Parsing: a timeline 3.0</a>.
      </footnote>
    </p>
    <p>
      The idea that the solution to the parsing problem must be
      stack-based is not without foundation.
      In 1965, the limits of computer technology are severe.
      For practitioners,
      any parsing technique that required much more
      than a reasonably-sized state
      machine and a stack,
      is not likely to happen.
      After all,
      only four years earlier,
      stacks were bleeding edge.
    </p>
    <p>The practitioners of 1965
      are inclined to believe that,
      like it or not,
      they are stuck with stack-based parsing.
      But why do the theoreticians feel compelled to follow them?
      The answer is that theoreticians talk themselves into
      it, using a misleading equivalence based
      on the behaviorist definition of language.
    </p>
    <h2>"Language" as of 1965</h2>
    <p>
      Knuth defines language as follows:
    </p>
    <blockquote>
      The language defined by G is<br>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      { &alpha; | S => &alpha; and &alpha; is a string over T }<br>
      namely, the set of all terminal strings derivable from S by using
      the productions of G as substitution rules.<footnote>
        Knuth 1965, p. 608.
      </footnote>
    </blockquote><p>
      Here G is a grammar whose start symbol is S and whose set
      of terminals is T.
      This is the behavorist definition of language
      translated into set-theoretic terms.
    </p>
    <p>Knuth proves, to the satisfaction of the profession,
      the "equivalence" of LR(k) and DPDA's.
      LR(k) is a class of grammars and the DPDA model is of
      languages -- sets of strings.
      At first glance, this is an "apples and oranges" comparison --
      how do you prove the equivalence of a class of languages
      and a class of grammars?
    </p>
    <p>
      Knuth does this by reducing the class of DPDA languages and the class
      of grammars to their lowest common denominator, which is the language.
      And, of course, the "language" in the usage of Parsing Theory
      is a set of strings, without consideration of their syntax.
    </p>
    <p>
      Every grammar, when stripped of its syntax, defines a language.
      So Knuth compares the language which results from stripping down
      the LR(k) grammars,
      to the language of DPDA's.
      After some very impressive mathematics,
      Knuth is able to show that the two languages are equivalent.
    </p>
    <p>
      In theoretical mathematics, of course,
      you can define "equivalent" however you like.
      But if the purpose is to suggest limits in practice,
      you have to be much more careful.
      And in fact, as Knuth's paper shows,
      if you equate languages and grammars,
      you get into a very serious degree of magical thinking.
      Using the Knuth algorithm,
    </p>
    <ul>
      <li>parsing LR(k) grammars for arbitrary k is hopelessly impractical;
      </li>
      <li>parsing LR(1) grammars is impractical, but close to the boundary<footnote>
          Given the capacity of computer memories in 1965,
          LR(1) was clearly impractical.
          With the huge computer memories of 2018,
          that could be reconsidered, but LR(1) is still restrictive
          and has poor error-handling,
          and few have looked at the possibility.
        </footnote>;
        and
      </li>
      <li>parsing LR(0) grammars is very practical.
      </li>
    </ul>
    <p>A problem for the relevance
      of Knuth's proof of equivalence is that,
      if you just look at sets of strings
      without regard to syntax,
      LR(1) and LR(k) are equivalent.
      That means that from the sets-of-strings point of view,
      hopelessly impractical and
      borderline impractical are the same thing.
    </p>
    <p>
      Worse, both LR(1) and LR(k) are equivalent to LR(0)
      for most applications.
      If you add
      an explicit end marker to an LR(1) language,
      which in most applications is easy to do<footnote>
        Some parsing applications, such as those which receive their input "on-line",
        can not determine the size of their input in advance.
        For these applications adding an end marker to their input is
        inconvenient or impossible.
      </footnote>,
      your LR(1) language becomes LR(0).
      Therefore, for most applications,
    </p>
    <center>
      LR(k) = LR(1) = LR(0)
    </center>
    <p>
      This means that, in the world of sets-of-strings,
      extremely impractical and very practical are usually the same thing.
    </p>
    <p>
      Clearly the world of sets of strings
      is a magical one,
      in which we can easily transport ourselves across the
      boundary between practical and impractical.
      We can take visions of a magical world back into the world of practice,
      but we cannot assume they will be helpful.
      In that light,
      it is no surprise that
      Joop Leo will show how to extend practical
      parsing well beyond LR(k).<footnote>
        Joop M. I. M.
        "A general context-free parsing algorithm running in linear time on every LR (k) grammar without using lookahead."
        <cite>Theoretical computer science</cite>, Volume 82, Issue 1, 22 May 1991, pp. 165-176.
        <a href="https://www.sciencedirect.com/science/article/pii/030439759190180A">
          https://www.sciencedirect.com/science/article/pii/030439759190180A</a>, accessed 24 April 2018.
      </footnote>
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
