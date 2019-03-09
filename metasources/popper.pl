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
The open Timeline and its critics
<html>
  <head>
  </head>
  <body>
      <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <blockquote>
	Let me repeat this important point.
	Scientific theories are not just the
	results of observation.
	They are, in the main, the products
	of myth-making and of tests.
	Tests proceed partly by way of observation,
	and observation is thus very important;
	but its function is not that of producing theories.
	It plays its role in
	rejecting, eliminating, and criticizing theories;
	and it challenges us to produce new myths,
	new theories which may stand up to these
	observational tests.<footnote>
	Karl Popper, <cite>Conjectures and Refutations</cite>, 
	Routledge and kegan Paul, 2002,
	p. 172.
	</footnote>
    </blockquote>
    <h2>The open timeline and its enemies</h2>
    <p>I've written a timeline history of parsing theory
    which is, despite being very technical,
    is by far my most popular writing.
    Despite, or because, of this,
    it is not without its critics.
    Many who praise it highly also have severe criticisms.
    </p>
    <p>The timeline have been accused of lack of objectivity and
    bias.
    In this post, I will take a careful look at methodology,
    and claim that I am innocent of the first charge
    because I am guilty, in one sense at least, of the second charge.
    That is, my timeline is objective because it precisely because
    it comes from a strong point of view.
    </p>
    <p>Novel as it might seem to some,
    my methodology is very much mainstream.
    In this piece, I will refer repeated to Karl Popper's writings
    on the traditions of science.
    Popper, in his turn, was much influenced by Einstein.
    Popper is hailed, correctly, as a champion of objectivity
    in science.
    But as you may have seen from the epigraph of this post,
    Popper's idea of objectivity is quite different in some respects from naive
    or "common sense" objectivity.
    </p>
    <h2>The "common sense" approach</h2>
<blockquote>"Always approach a case with an absolutely blank mind. It is always an advantage. Form no theories, just simply observe and draw inferences from your observations."<footnote>
The Adventure of the Cardboard Box</footnote></blockquote>
<blockquote>"I make a point of never having any prejudices, and of following docilely wherever fact may lead me."<footnote>
The Reigate Puzzle</footnote></blockquote>
<blockquote>"It is a capital mistake to theorize before one has data."<footnote>
A Scandal in Bohemia</footnote></blockquote>
<blockquote>"When you have eliminated the impossible, whatever remains, no matter how improbable, must be the truth."<footnote>
The Sign of Four</footnote></blockquote>
    <p>Most of those who accuse the timeline of lack of objectivity or of bias,
    do not state what they mean by those terms,
    which suggests they are thinking of an approach they expect to be
    shared as a matter of "common sense".
    But perhaps they have something in mind like Sherlock Holmes' approach.
    </p>
    <p>Many will regard Holmes' methods as just a disciplined version of
    "common sense", but in fact Holmes is completely wrong.
    A "blank mind" can observe nothing.
    There is no "data" without theory, just white noise.
    And you cannot characterize anything as "impossible",
    without theorizing in advance of it what kind of fact is possible,
    and what kind of fact is not.
    </p>
    <p>
    Using Holmes' methods as stated, he could not find a coconut on Coconut Island.
    If you read the deduction recorded in the Holmes' canon,
    you see that each of them requires <b>a lot</b>
    of theorizing, and not infrequently plain old speculation.
    For Holmes or anyone else to so much as find the door to
    Baker Street, they need a theory, explicit or implied,
    in advance.
    </p>
    <h2>Comments, etc.</h2>
    <p>
      The background material for this post is in my
    <a href="https://jeffreykegler.github.io/personal/timeline_v3">
    Parsing: a timeline 3.0</a>,
    and this post may be considered a supplement to "Timelime".
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
