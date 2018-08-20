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
    The Hutton and Meijer example is for Gofer,
    a now obsolete implementation of Haskell.
    To make the example more relevant,
    I wrote a parser for Haskell layout instead.
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
    <h2>Layout parsing and the off-side rule</h2>
    <p>It won't be necessary to know Haskell to follow this post.
    or even to understand any of its syntax beyond layout.
    This section will describe Haskell's layout parsing informally.
    Briefly, these two code snippets should have the same effect,
    and in my test suite, they produce the same AST:
    <pre><tt>
       let y   = a*b
	   f x = (x+y)/y
       in f c + f d
    </tt></pre>
    <pre><tt>
       let { y   = a*b
	   ; f x = (x+y)/y
	   }
    </tt></pre>
    The first code display uses Haskell's layout parsing,
    and the second code display uses explicit layout.
    In each, the "<tt>let</tt>" is followed by a block
    of declarations
    (symbol <tt>&lt;decls&gt;</tt>).
    Each decls contains one or more 
    declaration
    (symbol <tt>&lt;decl&gt;</tt>).
    For the purposes of determining layout,
    Haskell regards
    <tt>&lt;decls&gt;</tt> as a "block",
    and each
    <tt>&lt;decl&gt;</tt> as a block "item".
    In both displays, there are two items in
    the 
    <tt>&lt;decls&gt;</tt>
    block.
    The first item is
    <tt>y = a*b</tt>,
    and the second
    <tt>&lt;decl&gt;</tt> item
    is <tt>f x = (x+y)/y</tt>.
    </p>
    <p>F
    </p>
    </p>
    In explicit layout, curly braces surround the
    (symbol <tt>&lt;decls&gt;</tt>) block,
    and semicolons separate each
    <tt>&lt;decl&gt;</tt>.
    Implicit layout follows the "offside rule":
    The first element of the laid out block
    determines the "block indent".
    The first non-whitespace character of every subsequent non-empty line
    determines the line indent.
    The line indent is compared to the block indent.
    <ul>
    <li>If the line's indent is deeper than the block indent,
    then the line continues the current block item.
    </li>
    <li>If the line's indent is equal to the block indent,
    then the line starts a new block item.
    </li>
    <li>If the line's indent is less than the block indent,
    (an "outdent")
    then the line ends the block.
    An end of file also ends the block.
    </li>
    </ul>
    Lines containing only whitespace are ignored.
    Comments count as whitespace.
    </p>
    <p>
    Explicity semicolons can be used
    in implicit layout:
    If a semicolons occurs in implicit layout,
    it separates block items.
    In our test suite,
    the example
    <pre><tt>
       let y   = a*b;  z = a/b
	   f x = (x+y)/z
       in f c + f d
    </tt></pre>
    contains three 
    <tt>&lt;decl&gt;</tt> items.
    </p>
    <p>The examples in the displays above are simple.
    The test suite has
    a more complicated example
    with 6 blocks of 4 different kinds,
    nested to a maximum depth of 4.
    </p>
    <p>There are additional rules,
    including for tabs, Unicode characters and
    multi-line comments.
    These present no theoretical challenge to this parsing method,
    and none of them are implemented in the current Haskell subset
    parser.
    </p>
    <h2>The strategy</h2>
    <p>To tackle Haskell layout parsing, I chose to use a separate
    combinator for each layout block.
    Every block, therefore, had its own block and item symbols,
    its own block indent,
    and each was either explicit or implicit.
    </p>
    <p>From the point of view of its parent combinator,
    a child combinator is a lexeme,
    and the parse tree it produces is the
    value of the lexeme.
    Marpa can automatically produce an AST,
    and its adds lexemes values as they are produced,
    so this means that Marpa automatically assembles
    a parse tree for us.
    </p>
    <h2>Ruby Slippers semicolons</h2>
    <p>In explaining this algorithm, it may be best to explain first
    where the "missing" semicolons come from in the implicit layout.
    Marpa allows various kinds of events,
    including on discarded tokens.
    ("Discards" are tokens thrown away, and not used in the parse.
    The primary use of these in Marpa is for the handling of whitespace
    and comments.)
    </p>
    The following code sets an event named 'indent', which
    happens when Marpa find a newline followed by zero or more
    whitespace characters.<footnote>
    Single-line comments are dealt with properly by lexing them
    as a different token and discarding them separately.
    Handling multi-line comments is not yet implemented --
    it is easy in principle but
    tedious in practice and the examples drawn from the
    Haskell literature did not include any test cases.
    </footnote>
    This does not capture the indent of the first line of a file,
    but the standard requires that the first indent be treated as a
    special case anyway.<footnote>TODO
    </footnote>
    <pre><tt>
      :discard ~ indent event => indent=off
      indent ~ newline whitechars
    </tt></pre>
    <p>
    Indent events, like others, occur in the main read loop
    of each combinator.  Outdents and EOFs are dealt with by terminating
    the loop.<footnote>
    TODO: Code link</footnote>
    Line indents deeper than the current block indent are dealt with by
    resuming the read loop.
    .<footnote>
    TODO: Code link</footnote>
    Line indents equal to the block indent trigger the reading of a
    Ruby Slippers semicolon.<footnote>
    TODO: Code link
    </footnote>
    <pre><tt>
	$recce->lexeme_read( 'ruby_semicolon', $indent_start,
	    $indent_length, ';' )
    </tt></pre>
    </p>
    <h2>Ruby Slippers</h2>
    <p>
    In Marpa, a "Ruby Slippers" symbol is one which does not actually occur
    in the input.
    Ruby Slippers parsing is new with Marpa,
    and made possible because Marpa is left-eidetic.
    By left-eidetic, I mean that Marpa knows, in full
    detail, about the parse to the left of its current position,
    and can provide that information to the parsing app.
    This implies that Marpa also knows which tokens are acceptable
    to the parser at the current location,
    and which are not.
    </p>
    <p>The usage of the Ruby Slippers above is relatively incidental.
    <footnote>
    TODO: But that could change.  Error handling.
    </footnote>
    But Ruby Slippers parsing enables a very important trick for "liberal"
    parsing -- parsing where certain elements might be in some sense
    "missing".
    </p>
    <p>With the Ruby Slippers you can decide a "liberal" parser with
    a "fascist" grammar.
    This is, in fact, how the Haskell context-free grammar is designed --
    the official syntax requires explicit layout,
    but Haskell programmers are encouraged to omit most of the explicit
    layout symbols,
    and Haskell implementations are required to "dummy up" those
    symbols in some way.
    Marpa's method for doing this is left-eideticism and Ruby Slippers
    parsing.
    <p>The reference is to a well-known scene in the "Wizard of Oz" movie.
    Dorothy is in the fantasy world of Oz, desperate to return to Kansas,
    but, particularly after conventional Oz wizardry turns out to be affable fakery,
    she is completely at a loss as to how that might be done.
    The "good witch" Glenda appears and tells Dorothy that in fact she's always
    had what she's been wishing for right with her.
    The Ruby Slippers she's been wearing all along can return her to Kansas
    and all she needs to do is wish for it.
    </p>
    <p>In Ruby Slippers parsing,
    the "fascist" grammar wishes for lots of things that may not be in
    the actual input.
    Procedural logic here plays the part of a "good witch" -- it tells
    the "fascist" grammar that what it wants has been there all along,
    and provides it.
    To do this,
    the procedural logic has to has a reliable way of knowing what the parser
    wants.
    Marpa's left-eideticism provides this.
    </p>
    <h2>Ruby Slippers combinators</h2>
    <p>This brings us to a question
    we've posponed until now -- how do we know which combinator
    to call when?
    The answer is Ruby Slippers parsing.
    <pre><tt>
      laidout_decls ::= ('{') ruby_x_decls ('}')
	       | ruby_i_decls
	       | L0_unicorn decls L0_unicorn
    </tt></pre>
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
