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
Popper, Parsing and Objectivity
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
    which is, despite it being very technical,
    is by far my most popular writing.
    But it is not without its critics --
    in fact it is often criticized by those praise it
    in other respects.
    </p>
    <p>The timeline have been accused of lack of objectivity and
    bias.
    In this post, I will take a careful look at methodology,
    and claim that I am innocent of the first charge
    because I am guilty of the second.
    That is, my timeline is objective because it precisely because
    it comes from a strong point of view.
    </p>
    <p>It may sound as if I am "reaching", and being "cute"
    or "trolling",
    but, as you will see,
    my stance on these matters is not at all original.
    It fact, it follows Karl Popper, who is perhaps the philosopher of science
    taken most seriously by scientists.
    </p>
    <p>Popper is hailed, correctly, as a champion of objectivity
    in science.
    But as you may have seen from the epigraph of this post,
    Popper's idea of objectivity is quite different in some respects from naive "folk objectivity"
    or the objectivity of "common sense".
    </p>
    <p>"Folk objectivity" is, by its nature, not one thing to all folks.
    But one version of it goes something like:
    First, you recording "objective facts" or "observations".
    You examine these facts for any "bias", and remove it.
    What is left, it is alleged, with be the truth,
    and this truth becomes the basis of your theory.
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
