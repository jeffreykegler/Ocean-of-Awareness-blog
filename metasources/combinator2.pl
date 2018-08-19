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
Marpa and combinator parsing 2
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>A promise</h2>
    <p>
    In
    <a href="http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2018/05/combinator.html">
    a previous post</a>,
    I outlined a method for using the Marpa algorithm as the basis for
    better combinator parsing.
    This post is part of the delivery on that promise.
    </p>
    <p>To demonstrate Earley-driven combinator parsing,
    I choose the most complex example from the classic tutorial
    on combinator parsing by 
    <footnote>
    Graham Hutton and Erik Meijer,
    <cite>Monadic parser combinators</cite>, Technical Report NOTTCS-TR-96-4.
    Department of Computer Science, University of Nottingham, 1996,
    pp 30-35.
    <a href="http://eprints.nottingham.ac.uk/237/1/monparsing.pdf">
    http://eprints.nottingham.ac.uk/237/1/monparsing.pdf</a>.
    Accessed 19 August 2018.
    </footnote>.
    This is for the offside-rule parsing of a functional language --
    parsing where whitespace indicates the syntax.<footnote>
    I use
    whitespace-significant parsing as a convenient example
    for this post,
    for historical reasons and
    for reasons of level of complexity.
    This should not be taken to indicate that I recommend it
    as a language feature.
    </footnote>
    </p>
    <p>The Hutton and Meijer example is for Gofer,
    a new obsolete implementation of Haskell.
    To make the example more interesting,
    I wrote a Haskell parser instead.
    </p>
    <p>For tests,
    I used the two examples of layout in the 2010 Haskell
    standard and the four examples given in the "Gentle Introduction" to Haskell.
    I implemented only enough of the Haskell syntax to run
    these examples.
    The examples in the "Gentle Introduction" are short,
    but the ones in the 2010 Standard are moderately long,
    so this amounted to a substantial subset of Haskell's
    syntax.
    </p>
    <p>[ TO DO ].
    </p>
    <h2>What is still missing</h2>
    <p>
    I believe that
    the Haskell parser implemented for this post could be the basis of
    a full Haskell parser.
    It would have linear complexity,
    though as long as much of it is in Perl,
    speed and space requirements will be far inferior to that
    of native Haskell parsers.
    </p>
    <p>What is missing should be noted:
    Marpa::R2's tracing and error handling is excellent
    for single grammars,
    but it needs to be updated to understand about those
    grammars built into a combinator hierarchy.
    </p>
    <p>Large pieces of the Haskell grammar remain unimplemented.
    The missing parts are of two kinds:
    Those that these would be tedious, but unproblematic, to add;
    and those whose problems are completely separate from the
    issue of combinator parsing dealt with in this post.
    The unproblematic parts include support of Unicode, tabs, strings,
    and other bits of unimplemented syntax.
    Those most problematic part is fixity.
    </p>
    <p>[ TO HERE ].
    </p>
    <p>In the post on procedural parsing,
    the subparsers<footnote>
    In some of the descriptions of Marpa's procedural
    parsing, these subparsers are called "lexers".
    This emphasizes the usual case in current practice,
    where the subparsers are the bottom layer of the
    parsing application,
    and do not invoke their own child subparsers.
    </footnote>
    were like combinators,
    in that they could be called recursively,
    so that a parse could be built up from components.
    Like combinators,
    each child could return,
    not just a parse,
    but a set of parses.
    And, as in combinators, once a child combinator
    returned its value,
    the parent parser could resume parsing
    at a location specified by the child combinator.
    So what was missing?
    <p>A combinator,
    in order to handle ambiguity,
    returns not a subparse, but a set of subparses.
    In the full combinator model,
    each subparse can have its own "resume location".<footnote>
    In notational terms, a full combinator is a function of the form
    <br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <tt>A* &#8594; &#8473;( P &#215; A* )</tt>,
    <br>
    where <tt>A</tt> is the alphabet of the grammar;
    <tt>P</tt> is a representation of a single parser
    (for example, a parse tree);
    <tt>&#8473;(X)</tt> is the power set of a set <tt>X</tt>:
    and
    <tt>X &#215; Y</tt> is the Cartesian product
    of sets <tt>X</tt> and <tt>Y</tt>.
    The subparsers
    of the procedural parsing post
    were of the form
    <br>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <tt>A* &#8594; &#8473;( P ) &#215; A*</tt>.
    <br>
    </footnote>
    The procedural parsing post did not provide for multiple
    resume locations.
    We will now proceed to make up for that.
    </p>
    <h2>How it works</h2>
    <p>The Marpa parser has the ability to accept
    multiple subparses,
    each with its own length.
    This allows child subparses to overlap in any fashion,
    forming a mosaic as complex as the application needs.
    </p>
    </p>An Earley parser is table-driven --
    its parse tables consists of Earley sets,
    with an initial Earley set
    and one Earley set per token.
    This makes for a very simple idea of location.
    Location 0 is the location of the initial Earley set.
    Location <tt>N</tt> is the location of the Earley set after the <tt>N</tt>'th
    token has been consumed.
    </p>
    <p>Simplicity is great, but unfortunately
    this won't work for variable-length
    tokens.
    To handle those, Marpa introduces another idea of location:
    the <b>earleme</b>.
    Like Earley set locations,
    the earlemes begin at 0,
    and advance in integer sequence.
    Earley set 0 is always at earleme 0.
    Every Earley set has an earleme location.
    On the other hand,
    not every earleme has a corresponding Earley set --
    there can be "empty" earlemes.
    </p>
    <p>The lower-level interface for Marpa is Libmarpa.
    Every time Libmarpa adds a token,
    a length in earlemes must be specified.
    In the most-used higher level Marpa interfaces,
    this "earleme length" is always 1,
    which makes the Libmarpa location model collapse into the traditional one.
    </p>
    <p>
    The Libmarpa recognizer advances earleme-by-earleme.
    In the most-used higher level Marpa interfaces,
    a token ends at every earleme
    (unless of course that earleme is after end-of-input).
    This means that the most-used Marpa interfaces
    create a new Earley set every time they advance one earleme.
    Again, in this case, the Libmarpa model collapses into
    the traditional one.
    </p>
    <p>In Libmarpa and other lower-level interfaces,
    there may be cases where
    <ul>
    <li>one or more tokens
    end after the current earleme, but</li>
    <li>no tokens end <b>at</b> the current earleme.</li>
    </ul>
    In such cases the current earleme will be empty.
    </p>
    <p>This is only an outline of the basic concepts behind the
    Marpa input model.
    The formalisms are in the Marpa theory paper.<footnote>
    Kegler, Jeffrey.<a
    href="http://dinhe.net/~aredridel/.notmine/PDFs/Parsing/KEGLER,%20Jeffrey%20-%20Marpa,%20a%20practical%20general%20parser:%20the%20recognizer.pdf">
    "Marpa, a Practical General Parser: The Recognizer".</a>
    2013.
    Section 12, "The Marpa input model", pp. 39-40.
    </footnote>
    The documentation for Libmarpa and Marpa's other low-level interfaces contains
    more accessible,
    but detailed, descriptions.<footnote>
    Libmarpa API document,
    <a href="http://jeffreykegler.github.io/Marpa-web-site/libmarpa_api/stable/api_one_page.html#Input">
    the "Input" section</a>.
    Marpa::R2's NAIF interface allows
    access to the full Libmarpa input model
    and its documentation contains
    <a href="https://metacpan.org/pod/distribution/Marpa-R2/pod/Advanced/Models.pod">
    a higher-level description of Marpa's alternative input models.</a>
    There is also a thin Perl interface to Libmarpa,
    <a href="http://jeffreykegler.github.io/Marpa-web-site/libmarpa_api/stable/api_one_page.html#Input">the THIF interface</a>,
    which allows full access to the alternative input models.
    </footnote>
    </p>
    <h2>Value added</h2>
    <h3>Left-eidetic information</h3>
    <p>As readers of my previous posts<footnote>
    For example, the
    <a href="http://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2018/05/csg.html">
    post on procedural parsing</a> contains a good,
    simple, example of the use of Marpa's left-eideticism.
    </footnote>
    will know,
    Marpa is "left-eidetic" -- the application has access to everything to its left.
    This is an advantage over the traditional implementation of combinator parsing,
    where parse information about the left context may be difficult
    or impossible to access.<footnote>
    For best effect,
    left-eidetism and functional purity
    probably should be used in combination.
    For the moment at least,
    I am focusing on explaining the capabilities,
    and leaving it to others to find the monadic
    or other solutions that will allow programmers to leverage
    this power in functionally pure ways.
    </footnote>
    </p>
    <h3>More powerful linear-time combinators</h3>
    <p>Marpa parses a superset of LR-regular grammars in linear time,
    which makes it a more powerful "building block"
    than traditionally available for combinator parsing.
    This gives the programmer of a combinator parser more options.
    </p>
    <h3>State of the art worse-than-linear combinators</h3>
    <p>In special circumstances, programmers may want to use subparsers 
    which are worse than linear -- for example, they may know that
    the string is very short.
    Marpa parses context-free grammars in state of the art time.<footnote>
    Specifically O(n^2) for unambiguous grammars,
    and O(n^3) for ambiguous grammars.
    </footnote>
    </p>
    <h2>The code, comments, etc.</h2>
      To learn more about Marpa,
      a good first stop is the
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
