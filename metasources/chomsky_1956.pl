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
      Important papers produce important mistakes.
      A paper can contain a great many errors,
      and they will have no effect if the paper is ignored.
      On the other hand,
      even the good methods of
      a great paper can go badly wrong
      when successors copy those methods,
      without realizing that the reasons
      for them no longer hold.
    </p>
    <p>
      Chomsky's 1956 "Three Models" paper is about as influential
      as a paper can get.
      Just 12 pages,
      it's the paper in which the most-cited scholar of our
      time first outlined his ideas.
      It transformed linguistics,
      is one of the most important scientific papers ever.
    </p>
    <p>
      It is also the foundation paper of Theory of Parsing,
      the area of my own work
      and the subject of these blog posts.
      Chomsky does not consider himself a computer scientist
      and, after founding our field,
      has paid little attention to it.
      But in fact,
      the Chomskyan model has been more influential,
      in computer parsing than in Chomsky's own
      field of linguistics.
    </p>
    <p>
      Chomsky 1956 also puts him among the great mathematicians
      of all time.
      True, the rigor of his proofs more befits a slumming linguist
      than it would a professional mathematician,
      but at its heart,
      mathematics is not a technical field,
      or even about problem-solving --
      at its most fundamental,
      it is about framing problems so that they
      <b>can</b> be solved.
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
