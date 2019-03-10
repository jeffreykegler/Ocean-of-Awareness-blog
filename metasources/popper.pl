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
My "Timeline of Parsing", and its crime
<html>
  <head>
  </head>
  <body>
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <blockquote>Always approach a case with an absolutely blank mind.
      It is always an advantage.
      Form no theories, just simply observe and draw inferences from your observations.
      &mdash;
      <cite>
        Sherlock Holmes, quoted in "The Adventure of the Cardboard Box"<cite>.
        </cite></cite></blockquote>
    <blockquote>It is a capital mistake to theorize before one has data.
      &mdash;
      <cite>
        Holmes, in "A Scandal in Bohemia"</cite>.
    </blockquote>
    <blockquote>I make a point of never having any prejudices, and of following docilely wherever fact may lead me.
      &mdash;
      <cite>"The Reigate Puzzle"</cite>.
    </blockquote>
    <blockquote>When you have eliminated the impossible, whatever remains, no matter how improbable, must be the truth.
      &mdash;
      <cite>"The Sign of Four"</cite>.
    </blockquote>
    <blockquote>
      In imagination there
      exists the perfect
      mystery story.
      Such a story presents
      the essential clues, and compels us to form our own
      theory of the case.
      If we
      follow the plot carefully, we arrive at the complete
      all
      solution for ourselves just before the author's disclosure
      at the end of the book. The solution itself, contrary to
      those of inferior mysteries, does not disappoint us; more-
      over, it appears at the very moment we expect it.
      Can we liken the reader of such a book to the scientists,
      who throughout successive generations continue to seek
      solutions of the mysteries in the book of nature? The
      comparison is false and will have to be abandoned later,
      but it has a modicum of justification which may be
      extended and modified to make it more appropriate to
      the endeavour of science to solve the mystery of the
      universe.
      &mdash;
      <cite>Albert Einstein
        and Leopold Infeld</cite>.<footnote>
        Page 3,
        <cite>The Evolution of Physics</cite>,
        Scientific Book Club, London, 1938?</footnote>
    </blockquote>
    <blockquote>
      The scientist must, at least in part,
      commit his own crime, as well as carry out the investigation.
      &mdash;
      <cite>Einstein and Infeld</cite>.
      <footnote>
        "The Evolution of Physics", p. 78.
      </footnote>
    </blockquote>
    <h2>The timeline and its critics</h2>
    <p>I've written a timeline history of parsing theory
      which, even thought it is very technical,
      is by far my most popular writing.
      Despite, or because, of this,
      it is not without its critics.
      The most central criticisms are lack of objectivity,
      and bias.
      In this post, I will take a careful look at methodology,
      and will claim that I am innocent of the first charge
      because I am guilty, in one sense at least, of the second charge.
      That is, my timeline is objective because it precisely because
      it comes from a strong point of view.
    </p>
    <h2>The Sherlock Holmes approach</h2>
    <p>Most of those who accuse the timeline of lack of objectivity or of bias,
      do not state what they mean by those terms,
      which suggests they are thinking of an approach they expect to be
      shared as a matter of "common sense".
      But Einstein assumed his readers idea of discovery
      would come from Conan Doyle's Sherlock Holmes,
      and we will follow his lead in starting there.
    </p>
    <p>
      In fact Holmes's methods, as stated, are incapable of solving anything
      but the fictional and artificial problems he encounters.
      In real life, a "blank mind" can observe nothing.
      There is no "data" without theory, just white noise.
      Every "fact" gathered contains a prejudgement about what is
      relevant and what is not.
      And you cannot characterize anything as "impossible",
      without theorizing in advance of it what kind of fact is possible,
      and what kind of fact is not.
    </p>
    <p>
      If you look at the deduction recorded in the Holmes' canon,
      you see often involve <b>a lot</b>
      of theorizing, and sometimes outright speculation.
      To make it a matter of significance what the dogs in "Silver Blaze" did in the night,
      Holmes requires a theory of canine behavior,
      and this theory sometimes outpaces the facts by a considerable distance.
      Is it really true that only dangerous people own
      dangerous dogs?<footnote>
      "A dog reflects the family life.
      Whoever saw a frisky dog in a gloomy family, or a sad dog in a happy one?
      Snarling people have snarling dogs, dangerous people have dangerous ones."
      From "The Adventure of the Creeping Man".
      </footnote>
    </p>
    <h2>The Einstein approach</h2>
    <p>Einstein begins his description of a method 
    useful outside the pages of a novel at the start
    of his Chapter II.
    Many of his less determined readers must have given up
    the book when they encountered its first paragraph:
    <blockquote>
    The following pages contain a dull report of
The account some be boring very simple experiments.
not only because the description of experiments is un-
interesting in comparison with their actual performance,
but also because the meaning of the experiments does
not become apparent until theory makes it so. Our
purpose is to furnish a striking example of the role of
theory in physics.<footnote>
    Einstein and Infeld, p. 71.</footnote>
    </blockquote>
    <p>
    </p>
    <blockquote>
      In the first pages
      of our book we compared the role
      of an investigator
      to that of a detective who, after
      gathering the requisite facts, finds the right solution
      by pure thinking. In one essential this comparison must
      be regarded as highly superficial. Both in life and in
      detective novels the crime is given. The detective must
      look for letters, fingerprints, bullets, guns, but at least
      he knows that a murder has been committed. This is
      not so for a scientist. It should not be difficult to
      imagine someone who knows absolutely nothing about
      electricity, since all the ancients lived happily enough
      without any knowledge of it. Let this man be given
      metal, gold foil, bottles, hard-rubber rod, flannel, in
      short, all the material required for performing our
      three experiments. He may be a very
      cultured person,
      but he will probably put wine into the bottles, use the
      flannel for cleaning, and never once entertain the idea
      of doing the things we have described.
      For the detective
      the crime is given, the problem formulated: who
      killed Cock Robin?
      The scientist must, at least in part,
      commit his own crime, as well as carry out the investigation.
      Moreover, his task is not to explain just one
      case, but all phenomena which have happened
      or may
      still happen.<footnote>
        Page 78 of Einstein and Infeld.
      </footnote>
    </blockquote>
    <h2>Choosing a "highway"</h2>
    <blockquote>
      Through the maze of
      facts and concepts we had to choose some highway
      which seemed to us most characteristic and significant.
      Facts and theories not reached by this road had to be
      omitted. We were forced, by our general aim, to make
      a definite choice of facts and ideas. The importance of a
      problem should not be judged by the number of pages
      devoted to it. Some essential lines of thought have been
      left out, not because they seemed to us unimportant,
      but because they do not lie along the road we have
      chosen.<footnote>
        Page 78 of Einstein and Infeld.
      </footnote>
    </blockquote>
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
        Karl Popper,
        <cite>Conjectures and Refutations</cite>,
        Routledge and Kegan Paul, 2002,
        p. 172.
      </footnote>
    </blockquote>
    <h2>The end of the journey?</h2>
    <blockquote>
    This great mystery story
is still
unsolved.
We
cannot
even be sure that it has a final solution. --
<cite>Einstein and Infeld</cite><footnote>
Pp. 7-8</footnote>
</blockquote>
    </blockquote>
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
