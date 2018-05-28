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
Is a language just a set of strings?
<html>
  <head>
  </head>
  <body>
    <blockquote>
	But to my mind, though I am native here<br>
	And to the manner born, it is a custom<br>
	More honor’d in the breach than the observance.<footnote>
	<cite>Hamlet</cite>, Act I, scene iv.
	</footnote>
    </blockquote>
    <h2>Chomsky's "Three Models" paper</h2>
    <p>
      <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
      Important papers produce important mistakes.
      A paper can contain a great many errors,
      and they will have no effect if the paper is ignored.
      On the other hand,
      even the good methods of
      a great paper can go badly wrong
      when its methods
      outlive the reasons for using them.
    </p>
    <p>
      Chomsky's "Three Models" paper<footnote>
      Chomsky, Noam.
      "Three models for the description of language."
      <cite>IRE Transactions on information theory</cite>,
      vol. 2, issue 3, September 1956, pp. 113-124.
      </footnote>
      is about as influential
      as a paper can get.
      Just 12 pages,
      it's the paper in which the most-cited scholar of our
      time first outlined his ideas.
      Even at the time,
      linguists described its effect on their field as
      "Copernician".<footnote>
	Harris, Randy Allen,
	<cite>The Linguistics Wars</cite>,
	Oxford University Press, 1993,
	pp 33.
      </footnote>
      Bringing new rigor into what had been seen as a "soft"
      science, it turned lots of heads outside linguistics.
      It belongs on anyone's list of the most important scientific papers ever.<footnote>
      In this post I am treating the "Three models" paper
      as the "first"
      work of Chomskyan linguistics.
      Other choices can be justified.
      The next year, 1957,
      Chomsky published a book covering the same material: <cite>Syntactic Structures</cite>.
      <cite>Syntactic Structures</cite>
      was much more accessible,
      and attracted much more attention --
      the Chomskyan revolution did not really begin before
      it came out.
      On the other hand,
      both of these draw their material from Chomsky's
      1000-page
      <cite>Logical Structure of Linguistic Theory</cite>,
      which was completed in June 1955.
      But <cite>Logical Structure of Linguistic Theory</cite>
      was not published until 1975
      and then only in part.
      (See
      <a href="https://www.journals.uchicago.edu/doi/full/10.1086/686177">
      Radick, Gregory,
      "The Unmaking of a Modern Synthesis: Noam Chomsky, Charles Hockett, and the Politics of Behaviorism, 1955–1965"
      </a>.)
      </footnote>
    </p>
    <p>
      Given its significance,
      it is almost incidental that
      "Three models" is also the foundation paper of computer Parsing Theory,
      the subject of these blog posts.
      Chomsky does not consider himself a computer scientist
      and, after founding our field,
      has paid little attention to it.
      But in fact,
      the Chomskyan model has been even more dominant
      in computer parsing than in Chomsky's own
      field of linguistics.
    </p>
    <p>
      "Three Models" places Chomksy among the great mathematicians
      of all time.
      True, the elegance and rigor of Chomsky's proofs
      better befit a slumming linguist
      than they would a professional mathematician.
      But at its heart,
      mathematics is not a technical field,
      or even about problem-solving --
      at its most fundamental,
      it is about framing problems so that they
      <b>can</b> be solved.
      And Chomsky's skill at framing problems is astonishing.
    </p>
    <h2>A brilliant simplification</h2>
    <p>
      In 1956,
      Chomsky had a new approach to linguistics,
      and wanted to prove that his approach to language
      did things that
      the previous approach,
      based on finite-state models,
      could not.
      ("Finite-state" models, also known as Markov chains,
      are the predecessors of the regular expressions
      of today.)
      Brilliantly,
      Chomsky sets out to do this with extremely minimal definition of what
      a language is.
    </p>
    <blockquote>
      By a language then, we shall mean a set (finite or infinite) of
      sentences, each of finite length, all constructed from a finite
      alphabet of sysbols.  If A is an alphabet, we shall say that
      anything formed by concatenating the symbols of A is a string in
      A. By a grammar of the language L we mean a device of some sort that
      produces all of the strings that are sentences of L and only these.<footnote>
      Chomsky 1956, p. 114.
      </footnote>
    </blockquote>
    <p>Yes, you read that right --
    Chomsky uses a definition of language which has nothing to
    do with language actually meaning anything.
    A language, for the purposes of the math in "Three Models",
    is nothing but a list of strings.
    Similarly, a grammar is just something that enumerates
    those strings.
    The grammar does not have to provide any clue as to what
    the strings might mean.
    </p>
    <p>
        For example, Chomsky would require of a French grammar that one of the
	strings that it lists be
    </p>
    <blockquote>
      (42) Ceci n'est pas une phrase vraie.
    </blockquote>
    <p>But for the purposes of his demonstration,
    Chomsky does not require of his "grammar" that it
    give us any guidance as to what sentence (42) might mean.
    <p>
    Chomsky shows that there are English sentences that his "grammar" would
    list,
    and which a finite-state "grammar" would not list.
    Clearly if the finite-state grammar cannot even produce a sentence
    as one of a list,
    it is not adequate as a model of that language,
    at least as far as that sentence goes.
    <p>
    </p>
    Chomsky shows that there is,
    in fact,
    a large, significant class of sentences that
    his "grammars" can list,
    but which the finite-state grammars cannot list.
    Chomsky presents this as
    very strong evidence that
    his grammars will make better models
    of language
    than finite-state grammars can.
    </p>
    <h2>Other considerations</h2>
    <p>
    In addition to simplifying the math, Chomsky has two other good
    reasons to avoid dealing with meaning.
    A second reason is that
    semantics is a treacherously dangerous field of study.
    If you can make your point,
    and don't have to drag in semantics,
    you are crazy to do otherwise.
    Sentence (42), above,
    is just one example of the pitfalls
    that await those tackle who semantic issues.
    It echoes
    <a href="https://en.wikipedia.org/wiki/The_Treachery_of_Images">a famous Magritte<a>
    and translates to "This is not a true sentence".
    </p>
    <p>
    A third reason is that most linguists of Chomsky's time
    were Bloomfieldians.
    Bloomfield defined language as follows:
    </p>
    <blockquote>
    The totality of utterances that can be made in a speech
    community is the <b>language</b>
    of that speech-community.<footnote>
    Bloomfield, Leonard,
    "A set of Postulates
    for the Science of Language",
    <cite>Language</cite>, Vol. 2, No. 3 (Sep., 1926), pp. 153-164.
    The quote is definition 4 on p. 154.
    </footnote>
    </blockquote>
    <p>
    Bloomfield says "totality" instead of "set"
    and "utterances" instead of "strings",
    but for our purposes in this post the idea is the same --
    the definition is without regard to the meaning
    of the members of the set.<footnote>
    In case there is any doubt as to the link between
    the Chomsky and Bloomfield definitions,
    Chomsky also calls his strings,
    "utterances".
    See Chomsky, Noam, <cite>Syntactic Structures</cite>,
    2nd ed.,
    Mouton de Gruyter, 2002, p. 49
    </footnote>
    </p>
    <p>
    Bloomfield's omission of semantics is not accidental.
    Bloomfield wanted to establish linguistics as a
    science, and for Bloomfield
    claiming to know the meaning of
    a sentence was dangerously close to
    claiming to be able to read minds.
    You cannot base your work on mind-reading and expect people to
    believe that you are doing science.
    Bloomfield therefore suggested avoiding,
    totally if possible,
    any discussion of semantics.
    Most readers of Chomsky's paper in 1956 were Bloomfieldians --
    Chomsky has studied under a Bloomfieldian,
    and originally was seen as one.<footnote>
    Harris 1993, pp 31-34, p. 37.
    </footnote>
    By excluding semantics from his own model of language,
    Chomsky was making his paper maximally acceptable to
    his readership.
    </p>
    <h2>Semantics sneaks back in</h2>
    <p>
    But you did not have to read Chomsky's mind,
    or predict the future,
    to see that Chomsky
    was a lot more interested in semantics than
    Bloomfield was.
    Already in "Three Models",
    he is suggesting that his model is superior to
    its predecessors,
    because his model,
    when an utterance is ambiguous,
    produces multiple derivations to reflect that.
    Even better, these multiple derivations "look" like natural representations
    of the difference between meanings.<footnote>
    Chomsky 1956, p. 118, p. 123.
    </footnote>
    These insights,
    which dropped effortlessly out of Chomsky's grammars,
    were well beyond what the finite-state models were providing.
    </p>
    <p>
    By itself,
    Chomsky's argument, that his grammars were better
    because they could list more sentences,
    might have carried the day.
    With the demonstration that his grammars could do
    more than list sentences,
    but also could proivde insight into the structure and semantics
    of sentences,
    Chomsky's case was compelling.
    Young linguists wanted theoretical tools with this
    kind of power and those few
    older linguists not convinced struggled to find
    reasons why the young linguists could not
    have what they wanted.
    </p>
    <p>
    In later years,
    Chomsky made it quite clear what his position was:
    <blockquote>
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
    Compare this to Bloomfield:
    <blockquote>
    The statement of meanings is therefore the weak point in
    language-study, and will remain so until human knowledge
    advances very far beyond its present state. In practice, we define the
    meaning of a linguistic form, wherever we can, in terms of some
    other science.<footnote>
    Bloomfield, Leonard.
    <cite>Language</cite>.
    Holt, Rinehart and Winston, 1933, p. 140.
    </footnote>
    </blockquote>
    It is easy to see why linguists found Chomsky's
    expansion of their horizons irresistable.
    <p>
    </p>
    <h2>The tradition</h2>
    <p>Given the immense prestige of "Three models",
    it is unsurprising that it was closely studied by
    the pioneers of parsing theory.
    Unfortunately, what they picked up was not
    Chomsky's emphasis on the overriding importance
    of semantics,
    but the narrow definition of language
    that Chomsky had adopted from Bloomfield
    for tactical purposes.
    In the classic Aho and Ullman 1972 textbook, we have
    </p>
    <blockquote>
    A language over an alphabet &Sigma;
    is a set of strings over an alphabet &Sigma;.
    This definition encompasses almost everyone's notion of a language.<footnote>
    Aho, Alfred V., and Jeffrey D. Ullman.
    <cite>The theory of parsing, translation, and compiling</cite>.
    Vol. 1. Prentice-Hall, 1972, p. 16.
    </footnote>
    </blockquote>
    If this "encompasses" my notion of a language,
    it does so only in the sense that an avalanche encompasses
    a skier.
    </p>
    <p>
    From 1988, thirty years after Chomsky,
    here is another authoritative textbook of Parsing Theory
    defining "language":
    </p>
    <blockquote>
      A set V is an alphabet (or a vocabulary) if it is finite and
      nonempty.
      The elements
      of an alphabet V are called the symbols (or letters or characters) of
      V.
      A language L over V is any subset of the free monoid V*.
      The elements
      of a language L are called sentences of L.<footnote>
      Sippu, Seppo and Soisalon-Soininen, Eljas.
      <cite>Parsing Theory</cite>, Volume I,
      Springer-Verlag, 1988,
      p. 11.
      </footnote>
    </blockquote>
    <p>The language is now that of abstract algebra,
    but the idea is the same -- pure Bloomfield.<footnote>
    A welcome errancy from tradition, however, arrives with
    Grune, D. and Jacobs, C. J. H., <cite>Parsing Techniques: A Practical Guide</cite>,
    2nd edition, Springer, 2008.
    On pp. 5-7, they attribute the traditional "set of strings" definition
    to "formal linguistics".
    They
    point out that the computer scientist requires a grammar to
    not only list a set of strings, but provide a
    "structure" for each of them.<br><br>
    As an aside,
    Grune and Jacobs often depart from the "just stick to the math"
    approach taken by other textbooks parsing theory.
    They often give the history and motivation behind the math.
    My own work owes much to them.
    </footnote>
    </p>
    <h2>The problem</h2>
    <p>
    Interesting, you might be saying, that
    some textbook definitions are not everything they could be,
    but is there any effect on the daily practice of
    programming?
    </p>
    <p>
    The languages human beings use with each other
    are powerful,
    varied, flexible and endlessly retargetable.
    The parsers we use to communicate with computers
    are restrictive, repetitive in form,
    difficult to reprogram,
    and prohibitively hard to retarget.
    Is this because humans have a preternatural language ability?
    </p>
    <p>
    Or is there something wrong with the way we
    go about talking to computers?
    How the Theory of Parsing literature defines the term
    "language" may seem
    of only pedantic interest.
    But I will argue that it is a mistake which has everything
    to do with the limits of modern computer languages.
    <p>
    What is the problem with defining a language as a set of strings?
    Here is one example of how the textbook definition
    affects daily practice.
    Call one grammar <tt>SENSE</tt>:
    </p>
    <pre id="g-structure-op"><tt>
      SENSE ::= E
      E ::= E + T
      E ::= T
      T ::= T * P
      T ::= P
      P ::= number
    </tt></pre>
    <p>
    And call another grammar <tt>STRING</tt>:
    </p>
    <pre id="g-string-op"><tt>
      STRING ::= E
      E  ::= P OP E
      OP ::= '*'
      OP ::= '+'
      P  ::= number
    </tt></pre>
    <p>
    If you define a language as a set of strings,
    both
    <tt>SENSE</tt>
    and <tt>STRING</tt>
    recognize the same language.
    But it's a very different story if you
    take the intended meaning as
    that of traditional arithmetic expressions,
    and consider
    the meaning of the two grammars.
    </p>
    <p>
    <tt>SENSE</tt>
    recognizes the associativity and precedence of the two operators --
    the parse tree it produces could be used directly to evaluate an arithmetic
    expression and the answer would always be correct.
    The parse tree that <tt>STRING</tt> produces, if evaluated directly,
    will very often produce a wrong answer -- it does not capture
    the structure of an arithmetic expression.
    In order to produce correct results,
    the output of <tt>STRING</tt> could be put through a second phase,
    but that is the point --
    <tt>STRING</tt> left crucial parts of the job of parsing undone,
    and either some other logic does the job <tt>STRING</tt> did not do,
    or a wrong answer results.
    <p>
    It is much easier to write a parser for <tt>STRING</tt>
    than it is for <tt>SENSE</tt>.
    Encouraged by a theory that minimizes the
    difference,
    many implementations attempt to make do with <tt>SENSE</tt>.
    </p>
    <p>
    But that is not the worst of it.
    The idea that a language is a set of strings
    has guided research,
    and steered it away from the most promising lines.
    How, I hope to explain in the future.<footnote>
    Readers who want to peek ahead can look at my
    <a href="https://jeffreykegler.github.io/personal/timeline_v3#bib-Aho_and_Ullman_1972">
    Parsing: a timeline 3.0</a>.
    The tale is told there is from a somewhat different point of view,
    but no reader of "Timeline" will be much surprised by where
    I take this line of thought.
    </footnote>
    </p>
    <h2>Comments, etc.</h2>
    <p>
      The background material for this post is in my
    <a href="https://jeffreykegler.github.io/personal/timeline_v3#bib-Aho_and_Ullman_1972">
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
