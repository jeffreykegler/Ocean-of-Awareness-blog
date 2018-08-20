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
    The ones in the 2010 Standard are moderately long,
    so this amounted to a substantial subset of Haskell's
    syntax.
    </p>
    <p>The full code and test suite for this example are
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    on Github</a>.
    While they do not amount to a tutorial, the code has very
    extensive comments and
    readers who like to "peek ahead" are encouraged to do so.
    </p>
    <h2>Layout parsing and the off-side rule</h2>
    <p>It won't be necessary to know Haskell to follow this post.
    or even to understand more about its syntax than is necessary to
    illustrate layout.
    This section will describe Haskell's layout informally.
    Briefly, these two code snippets should have the same effect:
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
    <p>
    In my test suite, both code snippets produce the same AST.
    The first code display uses Haskell's layout parsing,
    and the second code display uses explicit layout.
    In each, the "<tt>let</tt>" is followed by a block
    of declarations
    (symbol <tt>&lt;decls&gt;</tt>).
    Each decls contains one or more 
    declarations
    (symbol <tt>&lt;decl&gt;</tt>).
    For the purposes of determining layout,
    Haskell regards
    <tt>&lt;decls&gt;</tt> as a "block",
    and each
    <tt>&lt;decl&gt;</tt> as a block "item".
    In both displays, there are two items in
    the block.
    The first item is
    <tt>y = a*b</tt>,
    and the second
    <tt>&lt;decl&gt;</tt> item
    is <tt>f x = (x+y)/y</tt>.
    </p>
    <p>
    In explicit layout, curly braces surround the block,
    and semicolons separate each
    item.
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
    <li>If the line's indent is less than the block indent
    (an "outdent"),
    then the line ends the block.
    An end of file also ends the block.
    </li>
    </ul>
    Lines containing only whitespace are ignored.
    Comments count as whitespace.
    </p>
    <p>
    Explicit semicolons can be used
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
    The two examples from the 2010 Standard are
    more complicated:
    6 blocks of 4 different kinds,
    with nesting twice reaching
    a depth of 4.
    The two examples in the 2010 Standard are the same
    except one uses implicit layout and the other uses
    explicit layout.
    In the test of my Haskell subset parser,
    the two examples produce identical ASTs.
    </p>
    <p>There are additional rules,
    including for tabs, Unicode characters and
    multi-line comments.
    These rules are not relevant in the examples I took from the Haskell literature,
    they present no theoretical challenge to this parsing method,
    and they are not implemented in this prototype Haskell parser.
    </p>
    <h2>The strategy</h2>
    <p>To tackle Haskell layout parsing, I use a separate
    combinator for each layout block.
    Every combinator, therefore, had its own block and item symbols,
    its own block indent,
    and each combinator applies implements exactly one of explicit or implicit layout.
    </p>
    <p>From the point of view of its parent combinator,
    a child combinator is a lexeme,
    and the parse tree it produces is the
    value of the lexeme.
    Marpa can automatically produce an AST,
    and its adds lexemes values as leaves of the AST.
    The effect is that Marpa automatically assembles
    a parse tree for us from the tree segments returned by the
    combinators.
    </p>
    <h2>Ruby Slippers semicolons</h2>
    <p>In outlining this algorithm, I will start by explaining
    where the "missing" semicolons come from in the implicit layout.
    Marpa allows various kinds of events,
    including on discarded tokens.
    ("Discards" are tokens thrown away, and not used in the parse.
    The typical use of token discarding in Marpa is for the handling of whitespace
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
    but that is not an issue --
    the 2010 Standard requires that the first indent be treated as a
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
    <footnote>
    TODO: Code link</footnote>
    Line indents equal to the block indent trigger the reading of a
    Ruby Slippers semicolon as shown in the following:<footnote>
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
    <p>The usage of the Ruby Slippers so far in this post is relatively incidental.
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
    First, here are some lexer rules for "unicorn" symbols.
    We use unicorns when symbols must appear in Marpa's lexer,
    but must never be found in actual input.
    </p>
    <pre><tt>
      :lexeme ~ L0_unicorn
      L0_unicorn ~ unicorn
      unicorn ~ [^\d\D]
      ruby_i_decls ~ unicorn
      ruby_x_decls ~ unicorn
    </tt></pre>
    <p>
    <tt>&lt;unicorn&gt;</tt> is defined to match 
    <tt>[^\d\D]</tt>.
    This pattern is all the symbols which are not digits
    and not non-digits -- in other words, it's impossible that this
    pattern will ever match any character.
    The rest of the statements declare other unicorn lexemes
    that we will need.
    <tt>&lt;unicorn&gt;</tt> and
    <tt>&lt;L0_unicorn&gt;</tt> are separate,
    because we need to use
    <tt>&lt;unicorn&gt;</tt> on the RHS of some lexer rules,
    and a Marpa lexeme can never occur
    on the RHS of a lexer rule.<footnote>
    The reason for this is that by default Marpa uses the LHS and RHS
    status of symbols to determine which symbols are lexemes.
    This makes a typical Marpa grammar quite elegant.
    and requires a minimum of explicit lexeme declarations
    (Lexeme declarations are statements with the <tt>:lexeme</tt>
    pseudo-symbol on their LHS.)
    As an aside,
    the Haskell 2010 Standard is not careful about the lexer/context-free
    boundary,
    and this required more use of Marpa's explicit lexeme declarations
    than usual.
    </footnote>
    </p>
    <p>In the above Marpa rule,
    <ul>
    <li>
    <tt>&lt;decls&gt;</tt> is the symbol from the 2010 Standard;
    </li>
    <li>
    <tt>&lt;ruby_i_decls&gt;</tt> is a Ruby Slippers symbol for
    a block of declarations with implicit layout.
    </li>
    <li>
    <tt>&lt;ruby_x_decls&gt;</tt> is a Ruby Slippers symbol for
    a block of declarations with explicit layout.
    </li>
    <li>
    <tt>&lt;laidout_decls&gt;</tt> is a symbol (not in the 2010 standard)
    for a block of declarations covering all the possibilities for
    a block of declarations.
    </li>
    </ul>
    <pre><tt>
      laidout_decls ::= ('{') ruby_x_decls ('}')
	       | ruby_i_decls
	       | L0_unicorn decls L0_unicorn
    </tt></pre>
    </p>
    <p>It is the expectation of a 
    <tt>&lt;laidout_decls&gt;</tt> symbol that causes child
    combinators to be invoked.
    Because <tt>&lt;L0_unicorn&gt;</tt> will never be found
    in the input,
    the 
    <tt>&lt;decls&gt;</tt> alternative will never match --
    it is there for documentation and debugging reasons.<footnote>
    Specifically, the presense of a 
    <tt>&lt;decls&gt;</tt> alternative silences the usual warnings about
    symbols inaccessible from the start symbol.
    These warnings can be silenced in other ways,
    but at the prototype stage it is convenient to check that
    all symbols supposed to be accessible through
    <tt>&lt;decls&gt;</tt> are in fact accessible.
    There is a small startup cost to allowing the extra symbols
    in the grammars,
    but the runtime the cost is probably not measureable.
    </footnote>
    Therefore Marpa, when it wants a
    <tt>&lt;laidout_decls&gt;</tt>,
    will look either for a
    <tt>&lt;ruby_x_decls&gt;</tt> 
    if a open curly brace is read;
    and a
    <tt>&lt;ruby_i_decls&gt;</tt> otherwise.
    Neither <tt>&lt;ruby_x_decls&gt;</tt> 
    or
    <tt>&lt;ruby_i_decls&gt;</tt> will ever be found in the
    input,
    and Marpa will reject the input,
    causing a "rejected" event.
    <h2>Rejected events</h2>
    <p>In this code, as often,
    the "good with" of Ruby Slippers does her work through
    "rejected" events.
    These events can be set up to happen when, at some parse
    location, none of the tokens that Marpa's internal lexer
    finds are acceptable.
    </p>
    <p>
    In the "rejected" event handler,
    we can use Marpa's left eideticism to find out what
    lexemes Marpa <b>would</b> consider acceptable.
    Specifically, there is a <tt>terminals_expected()</tt>
    method which returns a list of the symbols acceptable
    at the current location.
    </p>
    <pre><tt>
            my @expected =
              grep { /^ruby_/xms; } @{ $recce->terminals_expected() };
    </tt></pre>
    <p>We "grep" out all but the symbols with the "<tt>ruby_</tt>" prefix.
    There are only 4 non-overlapping possibilities:
    </p>
    <ul>
    <li>Marpa expects a 
    <tt>&lt;ruby_i_decls&gt;</tt>
    lexeme;
    </li>
    <li>Marpa expects a 
    <tt>&lt;ruby_x_decls&gt;</tt>
    lexeme;
    </li>
    <li>Marpa expects a 
    <tt>&lt;ruby_semicolon&gt;</tt>
    lexeme;
    </li>
    <li>Marpa does not expect
    any of the Ruby Slippers lexemes;
    </li>
    </ul>
    <p>If Marpa does not expect any of the Ruby Slippers
    lexemes, there was a syntax error in the Haskell code.<footnote>
    TODO:
    Currently the handling of these is simplistic.
    </footnote>
    <p>If a <tt>&lt;ruby_i_decls&gt;</tt>
    or a <tt>&lt;ruby_x_decls&gt;</tt>
    lexeme is expected, a child combinator is invoked.
    The Ruby Slippers symbol determines
    whether the child combinator looks for implicit
    or explicit layout.
    In the case of implicit layout, the location of
    the rejection determines the block indent.
    </p>
    <p>If a 
    <tt>&lt;ruby_semicolon&gt;</tt>
    is expected, then the parser is at the point where a
    new block item could start,
    but none was found.
    Whether the block was implicit or explicit,
    this indicates we have reached the end of the block,
    and should return control to the parent combinator.
    </p>
    <p>
    To explain, we look at both cases.
    In the case of an explicit layout combinator,
    the rejection should have been caused by a closing
    curly brace, and
    we return to the parent combinator
    and retry it.
    In the parent combinator, the closing curly brace
    will be acceptable.
    </p>
    <p>If we experience a "rejected" event while
    expecting a
    <tt>&lt;ruby_semicolon&gt;</tt> in an implicit layout
    combinator,
    it means we did not find an explicit semicolon;
    and we also never the right indent for creating a Ruby semicolon.
    In other words, the indentation is telling us we are at the end
    of the block.
    We therefore return control to the parent combinator.
    </p>
    <h2>Conclusion</h2>
    <p>
    With this, we've covered the major points of this Haskell prototype
    parser.
    In the code, the grammars from the 2010 standard are included for
    comparison, so a reader can easily determine what syntax we left out.
    It might be tedious to add the rest,
    but I believe it would be unproblematic, with one interesting exception:
    fixity.
    To deal with fixity, we may have to haul out the Ruby Slippers once
    again.
    </p>
    <h2>The code, comments, etc.</h2>
    <p>Full code and a test suite for this prototype can be found
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/haskell">
    on Github</a>.
    Note that, in order to guarantee they stay relevant,
    links for specific lines of code in this post will often be, not to the latest
    version, but to specific earlier commits.
    </p>
    <p>
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
