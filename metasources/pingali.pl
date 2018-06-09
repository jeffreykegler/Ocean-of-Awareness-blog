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
A new way to look at parsing
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Parsing with derivatives</h2>
    <p>In a very cordial Twitter exchange with Matt Might and
    and David Darais, Prof. Might asked why I was not looking at his
    derivatives-based approach.
    I answered that I already was --
    I see
    Marpa as an optimized version of the Might/Darais approach.
    </p>
    <p>This may sound strange.
    At first glance, the two algorithms seem about as different as
    two algorithms that address the same problem space can
    get.
    My Marpa parser is an Earley parser, table-driven
    and its parse engine is written in C language.
    The MDS (Might/Darais/Spiewak) parser is
    an extension of regular expressions
    which constructs states on the fly.
    MDS is uses combinators and is implemented via
    several functional programming languages.
    </p>
    <h2>Grammar Flow Graphs</h2>
    <p>How then could imagine that Marpa is another version of the MDS
    approach?
    The key was a paper sent
    me by Prof. Keshav Pingali at Austin: "Parsing with Pictures".
    The title is a little misleading:
    their approach is not <b>that</b> easy,
    and the paper does require some math.
    But it is a lot easier than the traditional way
    of learning the various approaches to parsing.
    Pingali and Bilardi suggest that their approach,
    taken out of the terse form it has in their
    papers,
    can make it a little easier to teach
    and understand Parsing Theory.
    </p>
    <h2>The MDS algorithm</h2>
    <p>
    For its functional programming language,
    the MDS paper uses Racket.
    The MDS parser is described directly,
    in the usual functional language manner,
    as a matching
    operation.
    This is optimized with laziness and memoization.
    Nulls are dealt with by computing their fixed points on the fly.
    The result is still highly inefficient, so MDS also
    implements "deep recursive simplication" -- in effect,
    strategically replacing laziness with eagerness.
    </p>
    <h2>Step 1: Extended regular expressions</h2>
    <p>
    Step 1 in going from the MDS algorithm to Leo/Earley/Marpa via
    the Pingali and Bilardi "pictures" is
    to notice both MDS and GFG's start at the same place:
    context-free grammars in the form of
    regular expressions extended to allow recursion.
    MDS starts with a match expression in Racket,
    and its Racket match expressions have a natural equivalent in a GFG --
    so natural you could imagine the MDS paper using GFG's
    as illustrations.
    </p>
    <h2>Step 2>: Following an NFA</h2>
    <p>
    The MDS and GFG approaches are also similar in their next step:
    Both follow an NFA by consuming a single character to produce a
    partial parse.
    For both, a partial parse is a duple consisting of a set of parses
    and a string.
    The string is the remaining input,
    and the set of parses is the parses so far.
    </p>
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
