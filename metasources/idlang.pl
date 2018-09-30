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
Identifying programming languages
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Which language is it in?</h2>
    <p>Given a source file, how do you determine what programming
    language it is in?
    Is it C, Cobol, Haskell, Lua, Javascript, Perl or Tex?
    For this post, I will take
    <a href="https://github.com/github/linguist">Github's <tt>linguist</tt></a>
    to represent the state of the art.
    It's very widely used,
    and the corpus that it analyzes is available to
    any competing approach.
    </p>
    <p>
    Github's linquist primarily trusts
    metadata, such as file name and the vim and shebang lines.
    The actual code is scanned as a last resort, using regexes.<footnote>
    See the methodology description in its README.md (
    <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md">
    permalink as of 30 September 2018</a>).
    </p>
    <p>
    Human programmers can identify programming languages at a glance.
    It seems highly unlikely that is ability is exceptionally human,
    an unexplainable talent available only to Homo Sapiens.<footnote>
    Of course, programmer can instantly identify only the languages they are familiar with,
    and human programmers slow down if the languages are very similar.
    But, both computers and chess champions memorize opening moves,
    except that the computer can memorize a larger book
    and recall it more quickly.
    In the same way,
    I expect that a computer should be able to know more languages
    and to tell apart closely related ones more quickly than humans.
    </footnote>.
    Much more likely is that our current techniques under-exploit
    the power of our electronic computers.
    </p>
    <p>Github's code statistics are much following,
    and I suspect, factor into many career and business decisions.
    Improving the quality of this data,
    or even confirming its accuracy,
    is likely to be of serious interest.
    </p>For files that mostly written in a single programming language,
    currently the majority,
    Github's numbers are probably roughly accurate.
    But <tt>linguist</tt> makes no attempt to accurately track multi-language files.
    And <tt>linguist</tt> ignores code embedded in documentation.
    As one example,
    I use an ad-hoc ad-hoc literate programming system<footnote>
    Largely undocumented, I call it Miranda (not relation to the Haskell precursor).
    </footnote>,
    which allows arbitrary other languages to be packaged inside Markdown.
    Under <tt>linguist</tt>, this code, in my case a substantial part of the package that
    contains it, is identified simply as "markdown"
    and, since Markdown is a documentation format,
    all this code,
    a substantial part of this package it is in,
    is ignored<footnote>
    See the <tt>linguist</tt> <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md#my-repository-isnt-showing-my-language">README.md</a>
    (permalink accessed as of 30 September 2018).
    <footnote>.
    </footnote>.
    How relevant is this to the overall statistics?
    At the moment, probably not very.
    Literate programming does not seem to be coming into use very rapidly.
    But if my home-grown Markdown-powered programming system is not one-of-a-kind,
    is part of a underground,
    it is one that is operating well beneath the radar of
    Github <tt>linguist</tt>.
    </p>
    <h2>An alternative</h2>
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
