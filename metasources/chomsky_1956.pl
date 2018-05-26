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
      when successors copy those methods,
      without realizing that the reasons
      for them no longer hold.
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
      is one of the most important scientific papers ever.
    </p>
    <p>
      It is also the foundation paper of Theory of Parsing,
      the area of my own work
      and the subject of these blog posts.
      Chomsky does not consider himself a computer scientist
      and, after founding our field,
      has paid little attention to it.
      But in fact,
      the Chomskyan model has been more influential,
      in computer parsing than in Chomsky's own
      field of linguistics.
    </p>
    <p>
      Chomsky 1956 also puts him among the great mathematicians
      of all time.
      True, the rigor of Chomsky's proofs better befits a slumming linguist
      than it would a professional mathematician.
      But at its heart,
      mathematics is not a technical field,
      or even about problem-solving --
      at its most fundamental,
      it is about framing problems so that they
      <b>can</b> be solved.
    </p>
    <h2>A brilliant simplification</h2>
    <p>
      In this framing,
      Chomsky has a brilliant insight,
      if one which will become a problematic tradition.
      Chomsky needs to show his new approach to grammars will do things that previous
      attempts at mathematizing linguistics have not.
      And he realizes how to do this with extremely minimal definition of what
      a language is.
    </p>
    <blockquote>
      By a language then, we shall mean a set (finite or infinite) of
      sentences, each of finite length, all constructed from a finite
      alphabet of sysbols.  If A is an alphabet, we shall say that
      anything formed by concatenating ths symbols of A is a string in
      A. By a grammar of the langnage L we mean a device of some sort that
      produces all of the strings that are sentences of L and only these.<footnote>
      Chomsky 1956, p. 114.
      </footnote>
    </blockquote>
    <p>Yes, you read that right --
    Chomsky uses a definition of language which has nothing to
    do with it meaning anything.
    A language, for the purposes of the math in "Three Models",
    is nothing but a list of strings.
    Similarly, a grammar is just something that enumerates
    those strings.
    The grammar does not have to provide any clue as to what
    the strings might mean.
    </p>
    <p>
        So Chomsky would require of a French grammar that one of the
	strings that it lists be
    </p>
    <blockquote>
      (Fr) Ceci n'est pas une phrase.
    </blockquote>
    <p>For the purposes of his demonstration,
    Chomsky does not require of his "grammar" that it
    give us any guidance as to what the French sentence might mean.
    In addition to simplifying the math, Chomsky has two other good
    reasons to avoid dealing with meaning.
    Semantics is a very difficult field and,
    if you can avoid it while still making your point,
    you are wise to do so.
    Sentence (Fr), above, which echoes
    <a href="https://en.wikipedia.org/wiki/The_Treachery_of_Images">a famous Magritte<a>
    and translates to "This is not a sentence" is a mild example of the pitfalls
    that await those tackle semantic issues.
    </p>
    <p>
    A third reason is that most linguists of Chomsky's time
    went to the other extreme.
    On the grounds that claims to know
    what was going on in others people's minds were not
    scientific,
    the structuralists banned any discussion of semantics.
    By excluding semantics from his own model of language,
    Chomsky can make his point in the terms that his opponents
    accept.
    </p>
    [ TODO: recognizer? ]
    </p>
    <p>
    [ TODO: Continue. ]
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
    <p>The language is that of abstract algebra,
    but the idea is the same.<footnote>
    A welcome departure from the tradition, however, arrives with
    Grune, D. and Jacobs, C. J. H. Parsing Techniques: A Practical Guide, 2nd edition. Springer, 2008.
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
