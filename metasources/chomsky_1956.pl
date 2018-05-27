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
Parsing languages versus parsing grammars
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
      It transformed linguistics,
      and is one of the most important scientific papers ever.<footnote>
      In this post I am calling the "Three models" paper the "first"
      work of Chomskyan linguistics.
      Other choices can be justified.
      The next year, 1957,
      Chomsky published a book covering the same material: <cite>Syntactic Structures</cite>.
      <cite>Syntactic Structures</cite>
      was much more accessible,
      and attracted much more attention,
      and the Chomskyan revolution did not really begin before
      it came out.
      On the other hand,
      both of these draw their material from Chomsky's
      1000-page
      <cite>Logical Structure of Linguistic Theory</cite>,
      which was completed in June 1955.
      But <cite>Logical Structure of Linguistic Theory</cite>,
      was not published until 1975,
      and then only in part.
      (See
      <a href="https://www.journals.uchicago.edu/doi/full/10.1086/686177">
      Radick, Gregory,
      "The Unmaking of a Modern Synthesis: Noam Chomsky, Charles Hockett, and the Politics of Behaviorism, 1955–1965"
      </a>.)
      </footnote>
      [ TODO: Work on this graf. ]
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
      the Chomskyan model has been more influential
      in computer parsing than in Chomsky's own
      field of linguistics.
    </p>
    <p>
      "Three Models" also places Chomksy among the great mathematicians
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
      and needed to prove that his approach to language
      did things that
      previous approaches could not.
      Brilliantly,
      he sets out to do this with extremely minimal definition of what
      a language is.
    </p>
    <blockquote>
      By a language then, we shall mean a set (finite or infinite) of
      sentences, each of finite length, all constructed from a finite
      alphabet of sysbols.  If A is an alphabet, we shall say that
      anything formed by concatenating ths symbols of A is a string in
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
    <h2>Avoiding meaning in order to address it</h2>
    </p>
    In addition to simplifying the math, Chomsky has two other good
    reasons to avoid dealing with meaning.
    A second reason is that
    semantics is treacherously dangerous field of study.
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
    of the members of the set.
    Bloomfield's omission of semantics is not accidental.
    Bloomfield wanted to establish linguistics as a
    science, and for Bloomfield
    claiming to know the meaning of
    a sentence was dangerously close to
    claiming to be able to read minds.
    You base a field on mind-reading and expect people to
    believe you are doing science,
    and Bloomfield therefore suggested avoiding,
    totally if possible,
    any discussion of semantics.<footnote>
    "The statement of meanings is therefore the weak point in
    language-study, and will remain so until human knowledge 
    advances very far beyond its present state. In practice, we define the
    meaning of a linguistic form, wherever wo can, in terms of some
    other science."
    Bloomfield, Leonard.
    <cite>Language</cite>.
    Holt, Rinehart and Winston, 1933, p. 140.
    </footnote>
    Most readers of Chomsky's paper in 1956 were Bloomfieldians --
    Chomsky has studied under a Bloomfieldian,
    and originally was seen as one.<footnote>
    Harris, Randy Allen,
    <cite>The Linguistics Wars</cite>,
    Oxford University Press, 1993,
    pp 31-34.
    </footnote>
    By excluding semantics from his own model of language,
    Chomsky was making his paper maximally acceptable to
    his readership.
    </p>
    <p>
    You didn't have to read Chomsky's mind to see that he
    was a lot more interested in semantics than
    Bloomfield was.
    Even in his 1956 paper, [...
    TODO: Continue this. ]
    </p>
    <h2>The tradition</h2>
    <p>Given the immense prestige of Chomsky's stunningly original and
    powerful work,
    it is little wonder that successors studied, and followed, his
    methods closely.
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
    it does so in the same sense that an avalanche encompasses
    a skier.
    </p>
    <p>
    Thirty years later,
    authoritative textbooks are still repeating that same idea.
    </p>
    <blockquote>
      A set V is an alphabet (or a vocabulary) if it is finite and
      nonempty.
      The elements
      of an alphabet V are called the symbols (or letters or characters) of
      V
      A language L over V is any subset of the free monoid V*.
      The elements
      of a language L are called sentences of L.<footnote>
      Sippu, Seppo and Soisalon-Soininen, Eljas.
      <cite>Parsing Theory</cite>, Volume I,
      Springer-Verlag, 1988,
      p. 11.
      </footnote>
    </blockquote>
    <p>The language has changed to that of abstract algebra,
    but the idea is exactly the same.<footnote>
    A welcome departure from the tradition, however, arrives with
    Grune, D. and Jacobs, C. J. H., <cite>Parsing Techniques: A Practical Guide</cite>, 2nd edition. Springer, 2008.
    On pp. 5-7, they attribute the traditional "set of strings" definition
    to "formal linguistics".
    They
    point out that the computer scientist requires a grammar to
    not only list a set of strings, but provide a
    "structure" for each of them.
    As an aside,
    Grune and Jacobs often depart from the "just stick to the math"
    approach to parsing theory,
    and give the history and motivation behind the math.
    My own work owes much to them.
    </footnote>
    <h2>The problem</h2>
    <p>
    Here are two grammars.
    Both <tt>STRUCTURE</tt>
    and <tt>STRING</tt>
    grammars recognize the same set of strings.
    </p>
    <pre id="g-structure-op"><tt>
      STRUCTURE ::= E
      E ::= E + T
      E ::= T
      T ::= T * P
      T ::= P
      P ::= number
    </tt></pre>
    <pre id="g-string-op"><tt>
      STRING ::= E
      E ::= P OP E
      OP ::= '*'
      OP ::= '+'
      P ::= number
    </tt></pre>
    <tt>STRING</tt> is a lot simpler.
    Many parsers can recognize 
    <tt>STRING</tt>,
    but most parsers in modern use
    require serious hackery to recognize
    <tt>STRUCTURE</tt>.
    On the other hand,
    <tt>STRUCTURE</tt>.
    recognizer the associativity and precedence of the two operators,
    and the parse tree it produces could be used directly to evaluate an arithmetic
    expression correctly.
    The parse tree that <tt>STRING</tt> produces, if evaluated directly,
    very often
    will <b>not</b> produce a correct answer.
    <tt>STRING</tt>, if it is to be evaluated correctly,
    must precede a second phase of processing --
    one that in effect does the parsing work that 
    <tt>STRING</tt>, left undone.
    <h2>A pedantic point?</h2>
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
