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
    <p>This post presents a practical, compact example which
    demonstrates a use case for both infinite lookahead
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
    </p>
    <p>
    Hoon is part of
    <a href="https://urbit.org/">the Urbit project</a>.
    Urbit is an effort to return control of the Internet
    experience to the individual user.
    (The Urbit community has, generously, been supporting my work on Hoon.)
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
we used the Internet as a supplement in our intellectual lives.
Today, we depend on it in our financial and social lives.
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
To make sure they can be run anywhere in the cloud<footnote>
In their present form, urbits run on top of Unix and UDP.
</footnote>,
they are based on a tiny virtual machine, called Nock.
To keep urbits compact and secure,
Urbit takes on code bloat directly --
Urbit is an original design from a clean slate,
with a new protocol stack.
    </p>
    <h2>About Hoon</h2>
    <p>
    Nock's "machine language" takes the form of trees of arbitrary precision integers.
    The integers can be interpreted as strings, floats, etc.,
    as desired.
    And the trees can be interpreted as lists,
    giving Nock a resemblance to a LISP VM.
    Nock does its own memory management
    and takes care of its own garbage collection.<footnote>
    Garbage collection and arbitrary precision may seem too high-level
    for something considered a "machine language",
    but our concepts evolve.
    The earliest machine languages required programmers to
    write their own memory caching logic
    and to create their own floating
    point representations,
    both things we now regard as much too low-level
    to deal with even at the lowest software level.
    </footnote>
    </p>
    <p>
    Traditionally, there are two ways to enter machine language,
    <ul>
    <li>Physically, for example,
    by toggling it into a machine's front panel.
    Originally, entering it physically was the only way.
    </li>
    <li>Indirectly, using
    assembler or some higher-level language, like C.
    Once these indirect methods existed, they
    rapidly took over as the most common way to create machine language.
    </li>
    </ul>
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
    The example for this post will be
    a <tt>hoonlint</tt> subset: a multi-line comment linter.
    Multi-line comments are the only Hoon syntax we will talk about.
    (For those who want to know more about Hoon,
    <a href="https://urbit.org/docs/learn/hoon/">there is a tutorial</a>.)
    </p>
    <p>
    </p>
    <h2>About Hoon comments</h2>
    <p>
    In basic Hoon syntax, multi-line comments are free-form.
    In practice, Hoon authors tend to follow a set of conventions.
    </p>
    <h3>Pre-comments</h3>
    <p>
    In the simplest case, a comment must precede the code it
    describes, and be at the same indent.
    These simple cases are called "pre-comments".<footnote>
    This post attempts to follow standard Hoon terminology, but
    for some details of Hoon's whitespace conventions,
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
    Hoon multi-line comments may also
    contain "inter-comments".
    The inter-comments are aligned depending on the syntax.
    In the display below, the inter-comments are aligned with the "rune" of the enclosing sequence.
    A "rune" is Hoon's rough equivalent of a "keyword".
    Runes are always digraphs of special ASCII characters.
    The rune in the following code is
    <tt>:~</tt>,
    and the sequence it introduces
    includes pre-comments, inter-comments and meta-comments.
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
    ::    :: pre-comment 4
    ::    [4 qax]
      ::
	  :: pre-comment 5
	  [5 tay]
      ==
    </tt></pre>
    <p>
    When inter-comments are empty, as they are in the above,
    they are called "breathing comments", because they serve to separate,
    or allow some "air" between, elements of a sequence.
    For clarity,
    the pre-comments in the above are further indicated:
    all and only pre-comments contain the text "<tt>pre-comment</tt>".
    </p>
    <h3>Meta-comments</h3>
    <p>
    The above code also contains a third kind of comment -- meta-comments.
    Meta-comments must occur at the far left margin -- at column 1.
    These are called meta-comments, because they are allowed
    to be outside the syntax structure.
    One common use for meta-comments is "commenting out" other syntax.
    In the above display, the meta-comments "comment out"
    the comment labeled "<tt>pre-comment 4</tt>"
    and its associated code.
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
    <h2>Hoon comment conventions</h2>
    <p>Hoon's basic syntax allows comments to be free-form.
    In practice, there are strict conventions for these comments,
    conventions we would like to enforce with <tt>hoonlint</tt>.
    <ol>
    <li>A multi-line comment may contain
    an "inter-part", a "pre-part",
    or both.
    </li>
    <li>If both an inter-part and a pre-part are present,
    the inter-part must precede the pre-part.
    </li>
    <li>The inter-part is a non-empty sequence of inter-comments
    and staircases.
    </li>
    <li>A pre-part is a non-empty sequence of pre-comments.
    </li>
    <li>Meta-comments may be inserted anywhere in either the pre-part
    or the inter-part.
    </li>
    <li>Comments which do not obey the above rules are
    <b>bad comments</b>.
    A <b>good comment</b> is any comment which is not a bad comment.
    </li>
    <li>A comment is not regarded as a meta-comment
    if it can be parsed as structural comment.
    An <b>structural comment</b> is any good comment which is
    not a meta-comment.
    </li>
    </ol>
    <h2>Grammar</h2>
    <p>We will implement these conventions using the BNF
    of this section.
    The sections to follow outline the strategy behind the BNF.
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
    Hoon's various string and in-line text syntaxes.
    </p>
    <p>Note that while combinator parsing is useful,
    it is a technique that can be oversold.
    Combinators have been much talked about in the functional programming
    literature<footnote>
    For a brief survey of this literature,
    see the entries from 1990 to 1996
    in my <a href="https://jeffreykegler.github.io/personal/timeline_v3">
    "timeline" of parsing history</a>.
    </footnote>,
    but the current flagship functional programming language compiler,
    the Glasgow Haskell Compiler,
    does not use combinators to parse its version of the Haskell --
    instead it uses a parser in the yacc lineage.<footnote><a
    href="https://github.com/ghc/ghc/blob/master/compiler/parser/Parser.y">This
    is the LALR grammar for GHC</a>, from GHC's Github mirror.
    </footnote>
    As a parsing technique on its own,
    the use of combinators is simply another way of packaging recursive
    descent with backtracking,
    and the two techniques share the same power,
    the same performance,
    and the same downsides.
    </p>
    <p>Marpa is much more powerful than either LALR (yacc-lineage) parsers or combinators,
    so we can save combinator parsing for those cases where
    combinator parsing really is helpful.
    One such case is lexer mismatch.
    </p>
    <h3>Lexer mismatch</h3>
    <p>The first programming languages, like BASIC and FORTRAN,
    were line-structured -- designed to be parsed line-by-line.<footnote>
    This is simplified.
    There were provisions for line continuation, etc.
    But, nonetheless, the lexers for these languages worked in
    terms of lines, and had no true concept of a "block".
    </footnote>
    After ALGOL, new languages were usually block-structured.
    Blocks can start or end in the middle of a line,
    and can span multiple lines.
    And blocks are often nested.
    </p>
    <p>A line-structured language requires its lexer to think in
    terms of lines,
    but this approach is completely useless for a block-structured
    language.
    Combining both line-structured and block-structured logic in the same lexer
    usually turns the lexer's code into a rat's nest.
    </p>
    <p>Calling a combinator every time
    a line-structured block is encountered eliminates the problem.
    The main lexer can assume that the code is block-structured,
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
    The comment linter cannot immediately distinguish between
    a prefix of the upper riser of a staircase,
    and a prefix of a sequence of inter-comments.
    When a tread and lower riser is encountered,
    the parser knows it has found a staircase,
    but not until then.
    And if the parse is of an inter-comment sequence,
    the comment linter will
    not be sure of this until the end of the sequence.
    </p>
    <h2>Technique: Infinite lookahead</h2>
    <p>
    As just pointed out,
    the comment linter does not know whether it is parsing a staircase or
    an inter-comment sequence until either
    <ul>
    <li>it finds a tread and lower riser, in which case
    it knows the correct parse will be a staircase; or
    </li>
    <li>it successfully reaches the end of the inter-comment sequence,
    in which case it knows the correct parse is an inter-comment sequence.
    </ul>
    To determine which of these two choices is the correct parse,
    the linter needs to read
    an arbitrarily long sequence of tokens --
    in other words, the linter needs to perform infinite lookahead.
    </p>
    <p>Humans deal with infinite lookaheads all the time --
    natural languages are full of situations that require them.<footnote>
    An example of a requirement for infinite lookahead
    is the sentence "The horse raced past the barn fell".
    Yes, this sentence is not, in fact, infinitely long,
    but the subclause "raced past the barn" could be anything,
    and therefore could be arbitrarily long.
    In isolation, this example sentence may seem unnatural,
    a contrived "garden path".
    But if you imagine the sentence as an answer to the question, "Which horse fell?",
    expectations are set so that the sentence is quite reasonable.
    </footnote>
    Modern language designers labor to avoid the need
    for infinite lookahead,
    but even so
    cases where it is desirable pop up.<footnote>
    See my blog post <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/08/rntz.html">
    "A Haskell challenge"</a>.
    </footnote>
    </p>
    <p>
    Fortunately, in 1991, Joop Leo published a method that
    allows computers to emulate infinite lookahead efficiently.
    Marpa uses Joop's technique.
    Joop's algorithm is complex,
    but the basic idea is to do what humans do in the same circumstance --
    keep all the possibilities in mind until the evidence comes in.
    </p>
    <p>
    </p>
    <h2>Technique: the Ruby Slippers</h2>
    <p>Recall that, according to our conventions,
    our parser does not recognize a meta-comment unless
    no structural comment can be recognized.
    We could implement this in BNF,
    but it is much more elegant to use the Ruby Slippers.<footnote>
        To find out more about Ruby Slippers parsing see the Marpa FAQ,
        <a href="http://savage.net.au/Perl-modules/html/marpa.faq/faq.html#q122">
          questions 122</a>
        and
        <a href="http://savage.net.au/Perl-modules/html/marpa.faq/faq.html#q123">
          123</a>;
        my
        <a href="file:///mnt2/new/projects/Ocean-of-Awareness-blog/metapages/annotated.html#PARSE_HTML">
          blog series on parsing HTML</a>;
	  my recent blog post
	  <a
	  href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/combinator2.html">
	  "Marpa and combinator parsing 2"</a>;
	  and my much older blog post
        <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2011/11/marpa-and-the-ruby-slippers.html">
          "Marpa and the Ruby Slippers"</a>.
      </footnote>
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
    <p>In our implementation, the Marpa parser, by default,
    looks only for structural comments.
    If the Marpa parser of our
    comment linter finds that the current input line is not
    a structural comment,
    the Marpa parser halts
    and tells the lexer that there is a problem.
    The lexer then asks the Marpa parser what it is looking for.
    In this case, the answer will always be the same:
    the Marpa parser will be looking for a meta-comment.
    The lexer checks to see if the current line is a comment
    starting at column 1.
    If there is a comment starting at column 1,
    the lexer tells the Marpa parser that its wish has come true --
    there is a meta-comment.
    </p>
    <p>Another way to view the Ruby Slippers is as a kind of exception
    mechanism for grammars.
    In this application, we treat inability to read an structural
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
    as above described for meta-comments,
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
    <p>On the second exception level, the current line
    will be read as either a <tt>&lt;BlankLine&gt;</tt>,
    or a <tt>&lt;BadComment&gt;</tt>.
    We know that every line must lex as either a
    <tt>&lt;BlankLine&gt;</tt>
    or a <tt>&lt;BadComment&gt;</tt> because our comment linter
    is called as a combinator,
    and the parent Marpa parser guarantees this.
    </p>
    <h2>Technique: Ambiguity</h2>
    <p>Marpa allows ambiguity,
    which could have been exploited as a technique.
    For example, in a simpler BNF than that we used above,
    it might be ambiguous whether a meta-comment belongs to an <tt>&lt;InterPart&gt;</tt>
    which immediately precedes it;
    or to a <tt>&lt;PrePart&gt;</tt> which immediately follows it.
    We could solve the dilemma by noting that it does not matter:
    All we care about is spotting bad comments and blank lines,
    so that picking one of two ambiguous parses at random will work fine.
    </p>
    <p>
    But efficiency issues are sometimes a problem with ambiguity
    and unambiguity can be a good way of avoiding them.<footnote>
    This, by the way,
    is where I believe parsing theory went wrong,
    beginning in the 1960's.
    In an understandable search for efficiency,
    mainstream parsing theory totally excluded not just ambiguity,
    but non-determinism as well.
    These draconian restrictions limited the
    search for practical parsers to a subset of techniques
    so weak that they cannot
    even duplicate human parsing capabilities.
    This had the bizarre effect of committing
    parsing theory to a form of
    "human exceptionalism" --
    a belief that human beings have a special ability to
    parse that computers cannot emulate.
    For more on this story,
    see my <a href="https://jeffreykegler.github.io/personal/timeline_v3">
    "timeline" of parsing history</a>.
    </footnote>
    Also, requiring the grammar to be unambiguous allows
    an additional check that is useful in the development phase.
    In our code we test each parse for ambiguity.
    If we find one, we know that <tt>hoonlint</tt> has a coding error.
    </p>
    <p>
    Keeping the parser unambiguous makes the BNF
    less elegant than it could be.
    To avoid ambiguity,
    we introduced extra symbols;
    introduced extra rules;
    and restricted the use of ambiguous tokens.
    </p>
    <p>Recall that I am using the term "ambiguous" in the strict technical
    sense that it has in parsing theory, so that a parser is only ambiguous
    if it can produce two valid parses for one string.
    An unambiguous parser
    can allow non-deterministism and
    can have ambiguous tokens.
    In fact, our example grammar does both of these things,
    but is nonetheless unambiguous.
    </p>
    <h3>Extra symbols</h3>
    One example of an extra symbol introduced to make this parser
    unambiguous is <tt>&lt;ProperPreComment&gt;</tt>.
    <tt>&lt;ProperPreComment&gt;</tt>
    is used to ensure that a
    <tt>&lt;PrePart&gt;</tt>
    never begins with a meta-comment.<footnote>
    This example illustrates the efficiency considerations
    involved in the decision to tolerate,
    or to exclude,
    efficiency.
    If <tt>n</tt> meta-comments occur between a
    <tt>&lt;InterPart&gt;</tt>
    and a <tt>&lt;PrePart&gt;</tt>,
    the dividing line is arbitrary,
    so that there are <tt>n+1</tt> parses.
    This will, in theory, make the processing time quadratic.
    And, in fact, long sequences of meta-comments might occur
    between the inter- and pre-comments,
    so the inefficiency might be real.
    </footnote>
    </p>
    <p>The BNF requires that the first line of a
    <tt>&lt;PrePart&gt;</tt>
    must be a
    <tt>&lt;ProperPreComment&gt;</tt>.
    This means that, if a
    <tt>&lt;MetaComment&gt;</tt> is found
    at the boundary between an
    <tt>&lt;InterPart&gt;</tt>
    and a
    <tt>&lt;PrePart&gt;</tt>,
    it cannot be the first line of the
    <tt>&lt;PrePart&gt;</tt>
    and so must be the last line of the
    <tt>&lt;InterPart&gt;</tt>.
    </p>
    </p>
    <h3>Extra rules</h3>
    <p>In our informal explanation of the comment conventions,
    we stated that an inter-part is a sequence, each element of
    which is an inter-comment or a staircase.
    While BNF that directly implemented this rule would be correct,
    it would also be highly ambiguous:
    If an inter-comment occurs before a tread or an upper riser line,
    it could also be parsed as part of the upper riser.
    </p>
    <p>To eliminate the ambiguity,
    we stipulate that if comment <b>can</b> be parsed as part of a staircase,
    then it <b>must</b> be parsed as part of a staircase.
    This stipulation still leaves the grammar non-deterministic --
    we may not know if our comment could be part of a staircase until
    many lines later.
    </p>
    <p>With our stipulation we know that, if an
    <tt>&lt;InterComponent&gt;</tt>
    contains
    a staircase, then that staircase must come before any of the inter-comments.
    In an <tt>&lt;InterComponent&gt;</tt>
    both staircases and inter-comments are optional, so the
    unambiguous representation of
    <tt>&lt;InterComponent&gt;</tt>
    is
    <pre><tt>
    InterComponent ::= Staircases
    InterComponent ::= Staircases InterComments
    InterComponent ::= InterComments
    </tt></pre>
    Notice that, although
    both staircases and inter-comments are optional,
    we do not include the case where both are omitted.
    This is because we insist that an
    <tt>&lt;InterComponent&gt;</tt>
    contain at least one line.
    </p>
    <h3>Ambiguous tokens</h3>
    <p>Our parser is not ambiguous, but
    it <b>does</b> allow ambiguous tokens.
    For example, a comment with inter-comment alignment
    could be either an
    <tt>&lt;InterComment&gt;</tt>
    or an
    <tt>&lt;UpperRiser&gt;</tt>;
    and our lexer returns both.
    The parser remains unambiguous, however, because
    only one of these two tokens will wind up in the
    final parse.
    </p>
    <p>Call the set of tokens returned
    by our parser for a single line,
    a "token set".
    If the token set contains more than one token,
    the tokenization is ambiguous for that line.
    If the token set contains only one token,
    the token set is called a "singleton",
    and tokenization is unambiguous for that line.
    </p>
    <p>
    To keep
    this parser unambiguous, we restrict the
    ambiguity at the lexer level.
    For example,
    our lexer is set up so
    that a meta-comment is never one of the alternatives
    in a lexical ambiguity.
    If a token set contains a
    <tt>&lt;MetaComment&gt;</tt>,
    that token set must be a singleton.
    The Ruby Slippers are used to enforce this.<footnote>
    Inter-comments and
    comments that are part of upper risers may start at column 1,
    so that, without special precautions in the lexer,
    an ambiguity between a structural comment
    and a meta-comment is entirely
    possible.
    </footnote>
    Similarly, the Ruby Slippers are used to guarantee that
    any set of tokens containing either
    a <tt>&lt;BadComment&gt;</tt>
    or a
    <tt>&lt;BlankLine&gt;</tt> is a singleton.
    </p>
    <h2>Code</h2>
    <p>This post did not walk the reader through the code.
    Instead, we talked in terms of strategy.
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/vgap">
    The code is available on Github</a>
    in unit test form.
    For those who want to see the comment-linter combinator in a context,
    a version of the code embedded in <tt>hoonlint</tt>
    in also on Github.<footnote>
    For the <tt>hoonlint</tt>-embedded form,
    the Marpa grammar is
    <a href="https://github.com/jeffreykegler/yahc/blob/714157124b46492e13968c786e400276017a3b85/Lint/Policy/Test/Whitespace.pm#L19">
    here</a>
    and the code is
    <a href="https://github.com/jeffreykegler/yahc/blob/714157124b46492e13968c786e400276017a3b85/Lint/Policy/Test/Whitespace.pm#L341">
    here</a>.
    These are snapshots -- permalinks.
    The application is under development,
    and probably will change considerably.
    Documentation is absent
    and testing is minimal,
    so that this pre-alpha embedded form of the code will mainly be useful
    for those who want to take a quick glance at the
    comment linter in context.
    </footnote>
    <h2>Comments on this blog post, etc.</h2>
    <p>
      To learn about Marpa,
      my Earley/Leo-based parser,
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
