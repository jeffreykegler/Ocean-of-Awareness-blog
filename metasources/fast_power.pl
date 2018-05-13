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
Parsers and Useful Power
<html>
  <head>
  </head>
  <body>
    <p>
      <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
      What do parser
      users want?
      What makes a parser<footnote>
      By "parser" in this post,
      I will mean a programmer's
      most powerful toolbox parser --
      what might be called the "flagship" parser.
      No parser will ever be the right one for all uses.
      </footnote>
      successful?
      In this post I will look at
      one aspect of
      that question,
      in light of an episode in
      the history of parsing.
    </p>
    <h2>Irons 1961</h2>
    <p>
      The first paper
      fully describing a parser was Irons 1961<footnote>
	For the reference to Irons, see
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
          V3 of my "Parsing: A Timeline"</a>.
	  The "Timeline" contains the background material for this post.
      </footnote>.
      The Irons parser was what is called "general",
      meaning that it can parse all of
      the "context-free grammars".
      That makes it
      far more powerful than most parsers
      in practical use today.
    </p>
    <p>
      But the Irons algorithm was not always fast in the general case.
      Irons 1961 used backtracking
      to achieve its power,
      so it would go exponential for many useful grammars.
    </p>
    <p>
      Among the grammars Irons 1961 could not parse quickly
      were those containing the all-important arithmetic expressions.
      Irons 1961 gave way to recursive descent.
    </p>
    <p>
      Recursive descent (RD) in its pure form,
      could not parse arithmetic expressions at all,
      but it could be customized with procedural code.
      That is, it could call specialized parsers which were
      reliably fast for specific sections of the input.
      The Irons parser was declarative,
      and not easy to cusomtize.
    </p>
    <h2>Raw power versus useful power</h2>
    <p>
      The contest between Irons parsing and recursive descent took place
      before the theory for analyzing algorithms was fully formed.<footnote>
      Even the term "analysis of algorithms" did not exist until 1969:
      see <a href="https://web.archive.org/web/20160828152021/http://www-cs-faculty.stanford.edu/~uno/news.html">
      Knuth, "Recent News"</a>.
      </footnote>
      In retrospect, we can say that,
      except in specialized uses,
      an acceptable parser for most practical uses
      must be linear or quasi-linear.<footnote>
        For more about "linear" and "quasi-linear",
	including definitions,
	see
        <a href="https://jeffreykegler.github.io/personal/timeline_v3">
          V3 of my "Parsing: A Timeline"</a>,
        in particular its 'Term: linear' section.
      </footnote>
      That is,
      the "useful power" of a parser is the class
      of grammars that it will parse in quasi-linear time.<footnote>
	While it is clearly the consensus among practitioners and theoreticians
	that, for parsing,
	practical time is quasi-linear or better,
	there are those who argue that worse-than-quasi-linear parsers
	are often the right ones for the job,
	and that research on them has been unwisely neglected.
	The dissenters are not without a case:
	For example, in natural language, while sentences are in theory
	infinite in length, in practice their average size is fixed.
	And while very long difficult-to-parse sentences do occur in some texts, such as
	older ones, it is normal for a human reader
	to have to spend extra time on them.
	So it may be unreasonable to insist that a parsing algorithm be
	quasi-linear in this application.
	</footnote>
    </p>
    <p>
      Useful power turns out to be more important,
      in practice,
      than raw power.
      Recursive descent won out over the
      Irons algorithm because,
      while the Irons algorithm had vastly more raw power,
      RD had slightly more "useful power".
    <p>
      It is nice to have raw power as well -- it means an algorithm can take on some specialized tasks.
      And raw power provides a kind of "soft failure" debugging mode for grammars with,
      for example, unintended ambiguities.
      But, in the eyes of the programming community, the more important measure of a parser
      is its useful power -- the class of grammars that it will parse at quasi-linear speed.
    </p>
    <h2>Stating the obvious?</h2>
    <p>
    That useful power is more important than raw power may seem,
    in retrospect,
    obvious.
    But in fact, it remains a live issue.
    In practice raw power and useful power are often confused.
    The parsing literature is not always as helpful as it could be:
    it can be hard to determine what the
    useful power of an algorithm is.
    </p>
    <p>
      And the Irons experiment with raw power is often repeated,
      in hopes of a different result.
      Very often,
      a new algorithm is a hybrid of two others:
      an algorithm with a lot of raw power,
      but which can go quadratic or worse;
      and a fast algorithm which lacks power.
      When the power of the fast algorithm fails,
      the hybrid algorithm switches over
      to the algorithm with raw power.
    </p>
    <p>
      It is a sort of
      cross-breeding of algorithms.
      The hope is that the hybrid algorithm has the best
      features of each of its parents.
      This works a lot better in botany than it does in parsing.
      Once you have a successful cross in a plant,
      you can breed from the successful hybrid
      and expect good things to happen.
      In botany,
      the individual crosses can have an extremely high
      failure rate,
      and cross-breeding can still succeed.
      But it's different when you cross algorithms:
      Even after you've succeeded with one parse,
      the next parse from your hybrid is a fresh new toss of the dice.
    </p>
    <h2>References, comments, etc.</h2>
    <p>
      To learn about
      my own parsing project,
      Marpa<footnote>
      Marpa's useful power is LR-regular,
      which properly contains
      every class of grammar in practical use: regular expressions,
      LALR,
      LL(k) for all k,
      LR(k) for all k,
      and the LL-regular grammars.
      <!-- For LLR, see Theorem 3, p. 448 in
      https://ris.utwente.nl/ws/portalfiles/portal/6126669,
      Nijholt, "On the parsing of LL-regular grammars" -->
      </footnote>,
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
