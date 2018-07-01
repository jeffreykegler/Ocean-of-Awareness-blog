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
Why is parsing considered solved? II
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <blockquote>The difference between theory and practice is
    that in theory there is no difference between
    theory and practice,
    but in practice, there is.<footnote>
    Attributed to Jan L. A. van de Snepscheut and Yogi Berra.
    See <a href="https://en.wikiquote.org/wiki/Jan_L._A._van_de_Snepscheut">
    https://en.wikiquote.org/wiki/Jan_L._A._van_de_Snepscheut</a>,
    accessed 1 July 2018.
    I quote my preferred form  of this --
    the one it takes in
    Doug Rosenberg and Matt Stephens,
    <cite>Use Case Driven Object Modeling with UML: Theory and Practice</cite>,
    2007,
    p. xxvii.
    Rosenberg and Stephens is also the accepted authority for its attribution.
    </footnote>
    </blockquote>
    <p>
    Once it was taken seriously that humans might have the power to, for
    example, "read" a chessboard in a way that computers could not beat.
    This kind of "computational mysticism" has taken a beating, but
    survives in one last stronghold -- parsing theory.
    <p>
    In a previous post I asked "Why is parsing considered solved?"
    If the state of the art of computer parsing is taken as anything close to its ultimate solution,
    then the human brain has some
    strange power that makes it much better at parsing than computers can be.
    It is very unlikely this would certainly be accepted as an explanation
    of any other problem,
    which raises the question:
    Why is it accepted for parsing theory.<footnote>
    As an aside, I am open to the idea that
    the human mind has abilities that Turing machines cannot improve on
    or even duplicate.
    When it comes to
    survival heuristics tied to the needs of human bodies, for example,
    it seems very reasonable to at least entertain the conjecture
    that the human mind might be near-optimal,
    particularly in big-O terms.
    But when it comes to ability to solve problems which can be formalized
    as "puzzles" -- and syntactic analysis is one of these --
    I think it is best to be extremely reluctant to accept
    human exceptionalism.
    </footnote>
    </p>
    <p>
    Previously I answered this question.  I explained why practitioners
    came to believe they'd reached the limit in 1965: Every practical
    parser was stack-driven
    </p>
    <h2>Comments, etc.</h2>
    <p>
      I encourage
      those who want to know more about the story of Parsing Theory
      to look at my
      <a href="https://jeffreykegler.github.io/personal/timeline_v3">
        Parsing: a timeline 3.0</a>.
      In particular,
      "Timeline 3.0" tells the story of the search for a good
      LR(k) subclass,
      and what happened afterwards.
    </p>
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
