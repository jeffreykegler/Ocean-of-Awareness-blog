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
Measuring language popularity
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>How to measure popularity</h2>
    <p>
      <a href="https://github.com/github/linguist">Github's
      linquist</a> is being see as the most trustworihy tool
      for estimating language popularity<footnote>
      TODO
      </footnote>,
      in large part because its counts are reported in terms
      of lines in a very large dataset.
      It is ironic, in this context,
      that <tt>linguist</tt>
      avoids looking at the code,
      preferring to use
      metadata -- file name and the vim and shebang lines.
      Scanned the actual code is a last resort.<footnote>
        <tt>linguist</tt>'s methodology is described in its README.md (
        <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md">
          permalink as of 30 September 2018</a>).
      </footnote></p>
    <p>
    <p>How accurate is this?
    For files that are mostly in a single programming language,
      currently the majority of them,
      <tt>linguist</tt>'s method are probably very accurate.<footnote>
      TODO:
      Human programmers can identify programming languages at a glance.
      It seems highly unlikely that is ability is exceptionally human,
      an unexplainable talent available only to Homo Sapiens.
        (Of course, programmer can instantly identify only the languages they are familiar with,
        and human programmers slow down if the languages are very similar.
        But, both computers and chess champions memorize opening moves,
        except that the computer can memorize a larger book
        and recall it more quickly.
        In the same way,
        I expect that a computer should be able to know more languages
        and to tell apart closely related ones more quickly than humans.)
      Much more likely is that our current techniques under-exploit
      the power of our electronic computers.
      </footnote>.
    </p>
    <p>But literate programming requires mixing languages.
    The source for
    much of the code used for the exammple in this blog post
    is a Markdown file, which contains both C and Lua.
    This code is "untangled" from the Lua by some ad-hoc scripts<footnote>
    TODO
    </footnote>.
    In my codebase, <tt>linguist</tt> indentifies this code simply
    as Markdown.
    <tt>linguist</tt> then ignores it,
    as it does all documentation files.<footnote>
        For the treatment of Markdown, see
        <tt>linguist</tt>
        <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md#my-repository-isnt-showing-my-language">README.md</a>
        (permalink accessed as of 30 September 2018).
        </footnote>.
	</p>
	<p>Do mistakes like this have much of an effect on
	<tt>linguist</tt>'s accuracy.
	My impression is that this sort of
	"guerrilla literate programming" is rare,
	so probably not.
	But if literate programming is becoming more popular,
	it may be slipping under <tt>linguist</tt>'s radar.
	And even those with a lot of faith in 
	<tt>linguist</tt>'s numbers should be happy to
	see them confirmed by more careful methods.
	</p>
    <h2>Token-by-token versus line-by-line</h2>
    <p>The problem with more careful counting,
    is that it cannot be done in a single pass
    with traditional parsing methods.<footnote>
    Another possibility is to do one scan
    pass per language, but that would be expensive --
    at least count there were 381 langauges in <tt>linguist</tt>'s
    database.
    Worse, it wouldn't solve the problem --
    "liberal" recognition of a single language will
    require a parser with most of the power required for a one-pass
    solution.
    </footnote>
    These cannot handle
    a parser must be able to handle ambiguity 
    <p>The method I propose combines Earley/Leo parsing and combinator parsing.
      The Earley/Leo portion of it is a general context-free parser,
      which is capable of parsing LR-regular
      grammars<footnote>
        In fact, the Earley/Leo implementation is linear
        for a superset of the LR-regular (LRR) grammars,
        which includes many ambiguous grammars.
        LRR is the set of all grammars which can be parsed deterministically
        using a finite regular set for lookahead.
        A "finite regular set" is some non-infinite set of regular expressions.
        Regular expressions, of course, can match arbitrarily long strings,
        and this means that LRR allows infinite lookahead.
      </footnote>
      in linear time.<footnote>
      </footnote>.
      When even this level of power fails,
      combinator parsing allows a subparser to be invoked.
    </p>
    <h2>The code, comments, etc.</h2>
    <p>A permalink to the
      full code and a test suite for this prototype,
      as described in this blog post,
      is
      <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/0df0aef7d6cb8590d3a33f857619e75f84786dd7/code/haskell">
        on Github</a>.
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
