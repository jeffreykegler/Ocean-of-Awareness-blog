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
  <body>
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <p>It is often said that parsing is a "solved problem".
    Given the level of frustration with the state of the art,
    the underuse of the very powerful technique of
    Language-oriented programming due to problematic tools,
    and the vast superiority of human parsing ability
    over computers,
    this requires explanation.
    On what grounds can someone say that parsing is "solved".
    </p>
    <p>To understand how parsing came to be consider solved,
    we need to look at the history of Parsing Theory.<footnote>
      This post takes the form of a timeline, and
      is intended to be incorporated in my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3>.
      Parsing: a timeline</a>.
      The earlier entires in this post borrow heavily from
      <a href="http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2018/05/chomsky_1956.html">
	    a previous blog post</a>.
      </footnote>
    In fact, we'll have to start before Parsing Theory
    itself,
    with a now nearly-extinct school of linguistics,
    and its desire to put the field on strictly
    scientific basis.
    </p>
    <h2>"Language" as of 1929</h2>
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
      Bloomfield is passing the buck in this way,
      because the positivist science of his time abhors
      unverifiable statements,
      and therefore any claims about mental states.
      A claim to know what someone "means" can be read
      as a claim to know what's in their mind.
      "Hard" sciences like physics, chemistry and even
      biology avoid dealing with unverifiable mental states,
      and Bloomfield wants to make the methods of linguistics
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
      Noam Chomsky earns his PhD at the Universtity of Pennsylvania.
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
      His definition of language now uses the terminology
      of set theory,
      but its substance comes from Bloomfield:
    </p><blockquote>
      By a language then, we shall mean a set (finite or infinite) of
      sentences, each of finite length, all constructed from a finite
      alphabet of sysbols.  If A is an alphabet, we shall say that
      anything formed by concatenating the symbols of A is a string in
      A. By a grammar of the language L we mean a device of some sort that
      produces all of the strings that are sentences of L and only these.<footnote>
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
    </blockquote><p>
      Chomsky does not intend to
      follow in the Bloomfieldian tradition of avoiding considerations
      of meaning, aka semantics:
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
    </blockquote><p>
      Already in "Three Models",
      Chomsky brings in semantics,
      when it is useful to show
      that his model is superior:
      When an utterance is ambiguous,
      Chomsky's new model produces multiple derivations
      each of which "look" like the natural representation
      of one of the meanings.
      Chomsky points out that this is a very
      desirable property for a model to have.<footnote>
        Chomsky 1956, p. 118, p. 123.
      </footnote>
    </p>
    <h2>Oettinger 1961</h2>
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
      (which he calls "pushdown stores") are very new.
      Oettinger, for example, does not use the terms "push" or "pop",
      but instead describes operations on his pushdown stores using
      a set of vector operations which will later form the basis
      of the APL language.
      As of 1961, all algorithms with acceptable speed are using
      stacks with various modifications.
      Oettinger express a hope:
    </p>
    <blockquote>
      The development of a theory of pushdown algorithms should
      hopefully lead to systematic techniques for generating
      algorithms satisfying given requirements to replace
      the ad hoc invention of each new algorithm.<footnote>
        Oettinger 1961, p. 127.
      </footnote>
    </blockquote><p>
      Oettinger hopes his pushdown store model of computing --
      what will eventually be called
      deterministic pushdown automata (DPDA's) --
      will become the basis of a theory of language
      computing encompassing both natural language
      (including the Russian which is the object of his own research)
      and computing languages like ALGOL.
      For natural language translation,
      DPDA's will prove totally inadequate.
      But DPDA's will continute to be the basis
      of hopes for a theory of computer language parsing.
      And the quote above more than hints at an expectation
      of One Stack Parsing Algorithm to Rule Them All.
    </p>
    <h2>Knuth 1965</h2>
    <p>In a pivotal LR(k) paper.
      that Donald Knuth sets out a theory that explains
      all the "tricks"<footnote>
      Knuth 1965, p. 607, in the abstract.
      </footnote>
      used for efficient parsing up to that time.
      Knuth sets out a comprehensive theory of stack-based
      parsing algorithms.
    </p>
    <p>
      For a start, Knuth shows that stack-based parsing is
      equivalent to a new and unexpected class of grammars
      LR(k), and he provides with a parsing algorithm for them.
      This algorithm might be expected to be "the one to rule
      them all".
      Unfortunately Knuth's LR(k), while deterministic and linear,
      is not practical -- it requires huge tables well beyond
      the memory capabilities of the time.
    </p>
    <p>
      Knuth, in his program for further research<footnote>
      Knuth 1961, pp. 637-639.
      </footnote>,
      suggests using grammars rewrites or table manipulations
      to streamline parsers for LR(k) or
      LR(k) subclasses.
      Knuth also suggests investigation of parsers for superclasses
      of and even describes a class of parsers with more aggressive lookahead -- LR(k,t).
      But he is clearly skeptical about LR(k,t)<footnote>
      "One might choose to this [more aggressive lookahead]
      left-to-right translation.", Knuth 1965, p. 639.
      </footnote>
      and, we may assume,
      even more skeptical about more general approaches.<footnote>
      That my conclusions about Knuth's skepticism are not misreadings
      is suggested by his own plans for his (not yet released) Chapter
      12 of the <cite>Art of Computer Programming</cite>,
      in which he planned to use pre-Chomskyan bottom-up methods. (See
      Knuth, Donald E., "The genesis of attribute grammars",
      <cite>Attribute Grammars and Their Applications</cite>,
      Springer, September 1990, p. 3.)
      In any case, and more importantly,
      after Knuth 1965
      the research community certainly was strongly
      skeptical of more general algorithms.
      </footnote>
    </p>
    <p>
      Knuth is certainly aware that DPDA determinism and
      linear time behavior are not the same thing.<footnote>
        Knuth 1965, p. 607: "execution time at worst
        proportional to the length of the string being parsed."
      </footnote>
      An algorithm can be more powerful than a DPDA,
      while still being linear.
      But linearity is a stand-in for "practical",
      and, with his discovery that even DPDA-based
      algorithms can be impractical,
      Knuth, and the research community,
      decide that it is extremely unlikely than more
      powerful computing models will also be faster in
      practice.
    </p>
    <h2>The term "language" as of 1965</h2>
    <p>
       Why was such a powerful skepticism based on the results for one
       computing model of computing?
       Stacks, as we now call them, are a natural model of computing,
       so it is reasonable to think they form a step on the hierarchy
       of tradeoffs of power against practical speed.
       But very important was the proof that LR(k) grammars were
       "equivalent" to DPDA's.
    </p>
    <h2>Comments, etc.</h2>
    <p>
      The background material for this post is in my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3>
    Parsing: a timeline 3.0</a>,
    and this post may be considered a supplement to "Timelime".
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
