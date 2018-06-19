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
Why the big deal about left recursion?
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Left recursion</h2>
    <p>This is a lot written about left recursion,
    and frankly much of what has been written adds to the mystery.
    In this post, I hope to frame the subject clearly and briefly.
    <p>
    </p>I assume the reader has some idea of what left recursion is.
    Informally, left recursion occurs when a symbol expands to something
    with itself on the left.
    This can happen directly, for example, if
    </p>
    <pre><tt>
    (1) A ::= A B
    </tt></pre>
    production <tt>(1)</tt> is in a grammar.
    Indirect left recursion happens when,
    for example,
    <pre><tt>
    (2) A ::= B C
    (3) B ::= A D
    </tt></pre>
    <tt>(2)</tt> and
    <tt>(3)</tt>
    are productions in a grammar.
    <pre><tt>
    (4) A ::= B A C
    (5) B ::= # empty
    </tt></pre>
    A grammar with productions
    <tt>(4)</tt> and
    <tt>(5)</tt>
    has a "hidden" left recursion.
    This is because
    <tt>&lt;A&gt;</tt>
    will ends up leftmost in derivations like:
    <pre><tt>
    (6) A  &#10230; B A C &#10230 A C
    </tt></pre>
    In derivation <tt>(6)</tt>,
    production <tt>(4)</tt> was applied,
    then production <tt>(5)</tt>.
    <p>For those into notation,
    a grammar is left recursive if and only if it allows a derivation of the
    form
    <pre><tt>
    (7) A  &#10230;<sup>+</sup> &beta; A &gamma; </tt> where <tt> &beta; = &epsilon;
    </tt></pre>
    In <tt>(7)</tt> <tt>&epsilon;</tt> is the empty string,
    and 
    <tt> &alpha; &#10230;<sup>+</sup> &beta;</tt>
    indicates that <tt>&alpha;</tt> derives <tt>&beta;</tt>
    in one or more rule applications.
    <h2>So, OK, what is the problem?</h2>
    <p>The problem with parsing left recursions is that if you are parsing
    using a derivation like
    <pre><tt>
    (8) A  &#10230; A B </tt>
    </tt></pre>
    then you have defined
    <tt>&lt;A&gt;</tt>
    in terms of 
    <tt>&lt;A&gt;</tt> --
    you have an infinite regress.
    Left recursions are a particular problem because almost all practical<footnote>
    </footnote>
    parsing methods proceed left to right,
    and derivations like <tt>(8)</tt> will lead them straight into
    an infinite regress.
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
