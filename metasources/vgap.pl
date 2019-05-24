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
Infinite Lookahead and Ruby Slippers
<html>
  <head>
  </head>
  <body>
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>About this post</h2>
    <p>This post presents a compact, practical example which
    nicely illustrates the need for both infinite lookahead
    and Ruby Slippers parsing.
    While the example itself is very simple,
    this post may not be a good first tutorial --
    it focuses on Marpa implementation strategy,
    instead of basics.
    </p>
    <h2>About Urbit</h2>
    <p>The example described in this post is one part of
    <tt>hoonlint</tt>.
    <tt>hoonlint</tt>, currently under development,
    will be a "lint" program for a language called Hoon.
    Hoon is part of the Urbit project.
    </p>
    <p>
    (The Urbit community has, generously, been supporting my work on Hoon.)
    Urbit is an effort to return control of the Internet
    experience to the individual user.
    </p>
    <p>
    The original Internet and its predecessors were cosy places.
    Users controlled their experience.
    Authority was so light you
    could forget it was there,
    but so adequate to its task that you could forget why it
    was necessary.
    What we old timers do remember of the early Internet was the feeling of entering
    into a "brave new world".
    </p>
    <p>
The Internet grew beyond our imaginings,
and our pure wonder of decades ago now seems ridiculous.
But the price has been a shift
of power which should be no laughing matter.
Control of our Internet experience now resides in
servers,
run by entities which make no secret of having their own interests.
Less overt, but increasingly obvious, is the single-mindedness with which they pursue
those interests.
</p>
<p>
And the stakes have risen.
In the early days,
we used on the Internet as a supplement in our intellectual lives.
Today, we depend on it for our financial and social lives.
Today, the server-sphere can be a hostile  place.
Going forward it may well become a theater of war.
    </p>
    We could try to solve this problem by running our own servers.
    But this is a lot of work, and only leaves us in touch with those
    willing and able to do that.  In practice, this seems to be nobody.
    </p>
    <p>
Urbit seeks to solve these problems with 
hassle-free personal servers, called urbits.
Urbits are journaling databases, so they are incorruptable.
To make sure they can be run anywhere in the cloud,<footnote>
In their present form, urbits run on top of Unix and UDP.
</footnote>
they are based on a tiny virtual machine.
To keep urbits compact and secure,
Urbit takes on code bloat directly:
Urbit is a totally original design from a clean slate,
with a new protocol stack, and a new VM called Nock.
</footnote>
    </p>
    <h2>About Hoon</h2>
    <p>
    Nock's "machine language" takes the form of trees of arbitrary precision integers.
    The integers can be interpreted as strings, floats, etc.,
    as desired.
    And the trees can be interpreted as lists,
    giving Nock a resemblance to a LISP VM.
    Nock does its own memory management
    and takes care of its own garbage collection.
    <footnote>
    Garbage collection and arbitrary precision may seem too high-level
    for something considered a "machine language",
    but our concepts evolve.
    The earliest machine languages required programmers to
    do their own memory caching and create their own floating
    point representations,
    both things we now regard as much too low-level
    to deal with even at the lowest software level.
    </footnote>
    </p>
    <p>
    Traditionally, you had to toggle machine language in physically
    or, more commonly, write it indirectly,
    in assembler or using some higher-level language, like C.
    Like traditional
    machine language, Nock cannot be written directly.
    Hoon is Urbit's equivalent of C -- it is Urbit's
    "close to the metal" higher level language.
    </p>
    <p>
    Not that Hoon looks much like C,
    or anything else you've ever seen.
    This is a Hoon program that takes an integer argument,
    call it <tt>n</tt>,
    and returns the first <tt>n</tt> counting numbers:
    <pre><tt>
    |=  end=@                                               ::  1
    =/  count=@  1                                          ::  2
    |-                                                      ::  3
    ^-  (list @)                                            ::  4
    ?:  =(end count)                                        ::  5
      ~                                                     ::  6
    :-  count                                               ::  7
    $(count (add 1 count))                                  ::  8
    </tt></pre>
    </p>
    <p>
    Hoon comments begin with a "<tt>::</tt>" and run until the next
    newline.
    The above Hoon sample uses comments to show line numbers.
    </p>
    <p>
    Our <tt>hoonlint</tt> subset is a multi-line comment linter,
    and multi-line comments are the only Hoon syntax we will talk about.
    (For those who want to know more about Hoon,
    <a href="https://urbit.org/docs/learn/hoon/">there is a tutorial</a>.)
    </p>
    <p>
    </p>
    <h2>About Hoon comments</h2>
    <p>
    In basic Hoon syntax, multi-line comments are free-form.
    But in practice, Hoon authors tend to follow a set of conventions.
    </p>
    <h3>Pre-comments</h3>
    <p>
    In the simplest case, a comment must precede the code it
    describes, and be at the same indent.
    These simple cases are called "pre-comments".<footnote>
    This post attempts to follow standard Hoon terminology, but
    for the details of Hoon's whitespace conventions,
    there is no settled terminology,
    and I have invented terms as necessary.
    The term "pre-comment" is one of those inventions.
    </footnote>
    For example, this code contains a pre-comment:
    <pre><tt>
	  :: pre-comment 1
	  [20 (mug bod)]
    </tt></pre>
    <p>
    <h3>Inter-comments</h3>
    Some Hoon code takes the form of a series or sequence of elements
    within a larger structure.
    and sequences are allowed
    "inter-comments".
    The inter-comments are indented to match the "keyword" of the sequence.
    The following code has both pre-comments and inter-comments.
    The inter-comments are indented to match the "keyword" digraph: <tt>:~</tt>,
    (Hoon's keyword digraphs are called "runes".)
    </p>
    <pre><tt>
      :~  [3 7]
      ::
	  :: pre-comment 1
	  [20 (mug bod)]
      ::
	  :: pre-comment 2
	  [2 yax]
      ::
	  :: pre-comment 3
	  [2 qax]
    ::::
    ::    :: pre-comment 3
    ::    [4 qax]
      ::
	  :: pre-comment 4
	  [5 tay]
      ==
    </tt></pre>
    <p>Note that the inter-comments in the above, are empty.
    They are called "breathing comments", and serve to separate,
    and give some air between, elements of a sequence.
    For clarity, all of the pre-comments
    contain the text "<tt>pre-comment</tt>".
    </p>
    <h3>Meta-comments</h3>
    <p>
    The above code also contains a third kind of comment -- meta-comments.
    Meta-comments must occur at the far left margin -- at column 1.
    These are called meta-comments, because they are allowed
    to be outside the syntax structure.
    One common use for meta-comments is "commenting out" other code.
    In the above display, the meta-comments comment out a pre-comment.
    </p>
    <h3>Staircase comments</h3>
    <p>Finally, there are "staircase comments", which are used
    to indicate the larger structure of Hoon sequences and other
    code.
    For example,
    <pre><tt>
    ::                                                      ::
    ::::  3e: AES encryption  (XX removed)                  ::
      ::                                                    ::
      ::
    ::                                                      ::
    ::::  3f: scrambling                                    ::
      ::                                                    ::
      ::    ob                                              ::
      ::
    </tt> </pre>
    <p>
    Each staircase consists of three parts.
    In lexical order, these parts are
    an upper riser,
    a tread, and a lower riser.
    The upper riser is a sequence of comments at the same
    alignment as an inter-comment.
    The tread is also at the inter-comment alignment,
    but must be 4 colons ("<tt>::::</tt>") followed
    by whitespace.
    The lower riser is a sequence of comments
    indented two spaces more than the tread.
    </p>
    </p>
    </p>
    <p>
    My current work is on a Marpa-powered tool to enforce Hoon's whitespace
    conventions.
    </p>
    <h2>Hoon comment conventions</h2>
    <p>Hoon's basic syntax allows comments to be free-form.
    But, in practice, there are strict conventions for these comments,
    conventions we would like to enforce with a <tt>lint</tt> for Hoon:
    a <tt>hoonlint</tt>.
    <ol>
    <li>A multi-line comment,
    may contain
    an "inter-part", a "pre-part",
    or both.
    </li>
    <li>If both an inter-part and a pre-part are present,
    the inter-part must preceed the pre-part.
    </li>
    <li>The inter-part must either be a sequence of
    one or more inter-comments;
    or a sequence of one or more staircases.
    </li>
    <li>A pre-part is always a sequence of
    one or more pre-comments.
    </li>
    <li>Meta-comments can occur anywhere in either the pre-part
    or the inter-part.
    </li>
    <li>Comments which do not obey the above rules are
    <b>bad comments</b>.
    A <b>good comment</b> is any comment which is not a bad comment.
    </li>
    <li>Upper risers, treads and inter-comments can also start at column 1,
    and a comment is not regarded as a meta-comment,
    if it can be parsed as ordinary comment.
    An <b>ordinary comment</b> is any good comment which is
    not a meta-comment.
    </li>
    </ol>
    <h2>Grammar</h2>
    <pre><tt>
    :start ::= gapComments
    gapComments ::= OptExceptions Body
    gapComments ::= OptExceptions
    Body ::= InterPart PrePart
    Body ::= InterPart
    Body ::= PrePart
    InterPart ::= InterComponent
    InterPart ::= InterruptedInterComponents
    InterPart ::= InterruptedInterComponents InterComponent

    InterruptedInterComponents ::= InterruptedInterComponent+
    InterruptedInterComponent ::= InterComponent Exceptions
    InterComponent ::= Staircases
    InterComponent ::= Staircases InterComments
    InterComponent ::= InterComments

    InterComments ::= InterComment+

    Staircases ::= Staircase+
    Staircase ::= UpperRisers Tread LowerRisers
    UpperRisers ::= UpperRiser+
    LowerRisers ::= LowerRiser+

    PrePart ::= ProperPreComponent OptPreComponents
    ProperPreComponent ::= PreComment
    OptPreComponents ::= PreComponent*
    PreComponent ::= ProperPreComponent
    PreComponent ::= Exception

    OptExceptions ::= Exception*
    Exceptions ::= Exception+
    Exception ::= MetaComment
    Exception ::= BadComment
    Exception ::= BlankLine
    </tt></pre>
    <h2>Technique: Combinator</h2>
    Our comment linter is implemented as a combinator.
    The main <tt>hoonlint</tt> parser invokes this combinator when it encounters
    a multi-line comment.
    Because of the main parser,
    we do not have to worry about confusing comments with
    Hoon various strings and in-line text syntaxes.
    </p>
    <p>Note that while combinator parsing is useful,
    it is a technique that can be oversold.
    Combinators are simply another way of looking at recursive
    descent with backtracking,
    and the two techniques share the same power,
    the performance,
    and the same downsides.
    Combinators have been much talked about in the functional programming
    literature<footnote>
    Refer to timeline.
    </footnote>,
    but, GHC, the flagship functional programming
    language parser,
    does not use combinators to parse itself --
    instead it uses a parser in the yacc lineage.<footnote><a
    href="https://github.com/ghc/ghc/blob/master/compiler/parser/Parser.y">This
    is the LALR grammar from GHC's Github mirror.</a>
    </footnote>
    </p>
    <p>Marpa is more powerful than either bison or combinators,
    and so can save combinator parsing for those cases where
    combinator parsing really is helpful.
    One such case is lexer mismatch.
    </p>
    <h3>Lexer mismatch</h3>
    <p>The first programming languages, like BASIC and FORTRAN,
    were line-structured -- designed to be parsed line-by-line.
    Lines were parsed one at a time.<footnote>
    This is simplified.
    There were provisions for line continuation, etc.
    But, nonetheless, the lexers for these languages worked in
    terms of lines, and had no true concept of a "block".
    </footnote>
    After ALGOL, languages more often were block-structured.
    Blocks could start or end in the middle of a line,
    and could span multiple lines.
    Also, blocks nested.
    </p>
    <p>A line-structured language requires its lexer to think in
    terms of lines,
    but this approach is completely useless for a block-structured
    language.
    Marpa does allow the lexer to ask the parent parser for context,
    which simplifies things somewhat.
    But basically,
    combining both line-structured and block-structured loing in the same lexer turns its
    code into a rats nest.
    </p>
    <p>Calling a combinator every time
    a line-structured block is encountered eliminates the problem.
    The main lexer can assume block-structured code,
    and all the line-by-line logic can go into combinators.
    </p>
    <h2>Technique: Non-determinism</h2>
    <p>
    Our grammar is non-deterministic,
    but unambiguous.
    It is unambiguous because,
    for every input,
    it will produce no more than one parse.
    </p>
    <p>
    It is non-deterministic because there is a case
    where it tracks two possible parses at once.
    it may keep more than one possibility in mind.
    The comment linter cannot immediately distinguish between
    the prefix of the upper riser of a staircase,
    and the prefix of a sequence of inter-comments.
    When a tread and lower riser is encountered,
    the parser knows it has found a staircase,
    but not until then.
    And if the parse is of an inter-comment sequence,
    the comment linter will not know until the end of the sequence.
    </p>
    <h2>Technique: Infinite lookahead</h2>
    <p>
    As just pointed out,
    the comment linter does not know whether it is parsing a staircase or
    and inter-comment sequence until either
    <ul>
    <li>it finds a tread and lower riser, in which case
    it knows the correct parse will be a staircase; or
    </li>
    <li>it successfully reaches the end of the inter-comment sequence,
    in which case it knows the correct parse is an inter-comment sequence.
    </ul>
    Determining which of these two choices is the correct parse,
    may require reading an arbitrarily long sequence of tokens --
    in other words, infinite lookahead.
    </p>
    <p>Humans deal with infinite lookaheads all the time --
    natural languages are full of situations that need them.</footnote>
    An example of a requirement for infinite lookahead
    is the sentence "The horse raced past the barn fell".
    Yes, this sentence is not, in fact, infinitely long,
    but the subclause "raced past the barn" could be anything,
    and therefore could be arbitrarily long.
    In isolation, this example sentence may not seem unnatural,
    a contrived "garden path".
    But if you imagine the sentence as an answer to the question, "Which horse fell?",
    expectations are set so that the sentence seems very natural.
    And, when the two expectations are balanced,
    humans parse these in the same way that Marpa does -- by keeping track
    of both possibilities until the end,
    and only deciding when the evidence comes in.
    </footnote>
    Fortunately, in 1991, Joop Leo published a method that
    allowed computer algorithms to efficiently emulate human lookahead.
    Joop's algorithm is complicated,
    but essentially it keep track of more than one potential parse,
    efficiently.
    Marpa uses Joop's technique.
    </p>
    <p>
    </p>
    <h2>Technique: the Ruby Slippers</h2>
    <p>Recall that, according to our conventions,
    our parser does not recognize a meta-comment unless
    no ordinary comment can be recognized.
    We could implement this in BNF,
    but it is much more elegant to use the Ruby Slippers.<footnote>
    Ruby Slippers reference</footnote>
    </p>
    <p>As those already familiar with Marpa may recall,
    the Ruby Slippers are invoked when a Marpa parser finds itself
    unable to proceed with its current set of input tokens.
    At this point, the lexer can ask the Marpa parser what token it <b>does</b> want.
    Once the lexer is told what the "wished-for" token is,
    it can concoct one, out of nowhere if necessary, and pass it to the Marpa parser,
    which then proceeds happily.
    In effect, the lexer acts like Glenda the Good Witch of Oz,
    while the Marpa parser plays the role of Dorothy.
    </p>
    <p>So, if the Marpa parser of our
    comment linter finds that the current input line is not
    one of those it is looking for, it halts
    and tells the lexer its problem.
    The lexer then asks Marpa what it is looking for,
    which will always be a meta-comment.
    The lexer checks to see if the current line is a comment
    starting at column 1,
    and if so, the lexer tells the Marpa parser its wish
    has come true.
    </p>
    <p>Another way to view the Ruby Slippers is as a kind of exception
    mechanism for grammars.
    In this application, we treat inability to read an ordinary
    comment as an exception.
    When the exception occurs,
    if possible, we read a meta-comment.
    </p>
    <h2>Technique: Error Tokens</h2>
    <p><b>Error tokens</b> are a specialized use of the Ruby Slippers.
    The application for this parser is "linting" --
    checking that the comments follow conventions.
    As such, the main product of the parser is not the parse --
    it is the list of errors gathered along the way.
    So stopping the parser at the first error does not make sense.
    </p>
    <p>
    What is desirable is to treat all inputs as valid,
    so that the parsing always runs to the end of input,
    in the process producing a list of the errors.
    To do this, we want to set up the parser so that it reads
    special "error tokens" whenever it encounters a reportable error.
    </p>
    <p>This is perfect for the Ruby Slippers.
    If an "exception" occurs,
    as described for meta-comment,
    but no meta-comment is available,
    we treat it as a second level exception.
    </p>
    <p>When would no meta-comment be available?
    There are two cases:
    <ul><li>The line read is a comment,
    but it does not start at column 1.
    </li>
    <li>The line read is a blank line (all whitespace).
    </li>
    </ul>
    <p>On a second level of exception, the current line
    is read as either a <tt>&lt;BlankLine&gt;</tt>,
    or a <tt>&lt;BadComment&gt;</tt>.
    [ TODO: Point out somewhere that one or other will always
    be the case. ]
    </p>
    <h2>Technique: Ambiguity</h2>
    <p>Marpa allows ambiguity,
    and this can be exploited as a technique.
    For example, in a simpler BNF than that we used above,
    it might be ambiguous whether a meta-comment belongs to an <tt>&lt;Interpart&gt;</tt>
    which immediately preceeds it;
    or a <tt>&lt;Prepart&gt;</tt> which immediately follows it.
    We could solve the dilemma by noting that it does not matter -- the
    meta-comment will get reported either way,
    so picking one of the parses at random will work fine.
    </p>
    <p>For our comment linter, we will make the grammar
    slightly more complicated,
    in order to keep it unambiguous.
    This makes the grammar less elegant,
    but but avoids the efficiency issues
    that can be a problem with ambiguity.<footnote>
    If <tt>n</tt> meta-comments occur between a
    <tt>&lt;Interpart&gt;</tt>
    and a <tt>&lt;Prepart&gt;</tt>, the dividing line is arbitrary,
    so that there are <tt>n+1</tt> parses.
    This will, in theory, make the processing time quadratic.
    And, in fact, a long sequences of meta-comments might occur
    between the inter- and pre-comments,
    so the inefficiency might be real.
    </footnote>
    Also, requiring the grammar to be unambiguous allows
    an additional check on our parsing logic.
    In our code we test each parse for ambiguity.
    If we find one, we know that <tt>hoonlint</tt> has a coding error.
    </p>
    <p>Some of the work in keeping 
    this parser unambiguous is delegated to the lexer.
    We used our Ruby Slippers "exception mechanism" to
    guarantee that no line is, for example,
    both a meta-comment and an inter-comment.<footnote>
    Inter-comments may start on line 1,
    so an ambiguity between an inter-comment and
    a meta-comment is entirely
    possible.
    </footnote>
    </p>
    <h2>Code</h2>
    <p>This post did not walk the reader through the code.
    Instead, it talked mostly in terms of strategy.
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/draft/code/vgap">
    The code is available on Github</a>
    in unit test form.
    [ TODO: Change link to gh-pages branch ]
    For those who want to see comment-linter combinator in a context,
    a version of the code,
    embedded in its application, <tt>hoonlint</tt>,
    in also on Github.<footnote>
    For the <tt>hoonlint</tt>-embedded form,
    the Marpa grammar is
    <a href="https://github.com/jeffreykegler/yahc/blob/714157124b46492e13968c786e400276017a3b85/Lint/Policy/Test/Whitespace.pm#L19">
    here</a>
    and the code is
    <a href="https://github.com/jeffreykegler/yahc/blob/714157124b46492e13968c786e400276017a3b85/Lint/Policy/Test/Whitespace.pm#L341">
    here</a>.
    These are permalinks.
    The application is under development,
    and probably will change considerably.
    In this pre-alpha embedded form, documentation and unit testing are
    lacking,
    so that this pre-alpha embedded form will mainly be useful
    for those who want to take a glance at the
    comment linter in a context.
    </footnote>
    <h2>Comments on this blog post, etc.</h2>
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