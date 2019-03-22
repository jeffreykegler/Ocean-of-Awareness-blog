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
Parsing, Holmes, Einstein and Popper
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
      those of inferior mysteries, does not disappoint us;
      moreover, it appears at the very moment we expect it.
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
    <h2>The Sherlock Holmes approach</h2>
    <p>I've written a timeline history of parsing theory
      which, even though it is very technical,
      is my most popular writing.
      Despite, or because, of this,
      it is not without its critics.
      Most of those who accuse the timeline of lack of objectivity or of bias,
      do not state what they mean by those terms.
      Einstein assumed his reader's idea of methods of proper investigation,
      in science as elsewhere,
      would be similar to those Conan Doyle's Sherlock Holmes,
      and I will follow Einstein's lead in starting there.
    </p>
    <p>
      If you look at the deduction recorded in the Holmes' canon,
      you see often involve <b>a lot</b>
      of theorizing, and more than a little outright speculation.
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
    <p>
      Holmes's methods, at least as stated in the Conan Doyle stories,
      are incapable of solving anything
      but the fictional and artificial problems he encounters.
      In real life, a "blank mind" can observe nothing.
      There is no "data" without theory, just white noise.
      Every "fact" gathered relies on many prejudgements about what is
      relevant and what is not.
      And you certainly cannot characterize anything as "impossible",
      unless you have, in advance, a theory about what is possible.
    </p>
    <h2>The Einstein approach</h2>
    <p>Einstein, in his popular history of physics,
    describes a method useful outside the pages of a novel.
    He begins his description of it at the start
    of his Chapter II:
    <blockquote>
    The following pages contain a dull report of
    The account some be boring very simple experiments.
    not only because the description of experiments is uninteresting
    in comparison with their actual performance,
    but also because the meaning of the experiments does
    not become apparent until theory makes it so. Our
    purpose is to furnish a striking example of the role of
    theory in physics.<footnote>
    Einstein and Infeld, p. 71.</footnote>
    </blockquote>
    <p>Einstein follows with a series of the kind of experiments
    that are performed in high school physics classes.
    One might imagine these experiments allowing an observer
    to deduce the basics of electromagnetism
    using materials and techniques available for centuries.
    </p>
    <p>But, and this is Einstein's point,
    this is not how it happened.
    The theory came <b>first</b>,
    and the experiments were devised afterwards.
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
    <h2>Theory, then observation</h2>
    <p>Einstein results impressed many people,
    and led the philosophy Karl Popper
    to give careful attention to his methods.
    [ TODO: More on Popper ]
    Popper undertook a systematic formulation
    of Einstein's approach.
    <p>
    </p>
    Popper first focused on what he called "demarcation" --
    what is it that distinguishes a science from non-science.
    (By "science", Popper meant a "hard science.
    Popper is frequently mistaken to be saying that soft sciences,
    social sciences and philosophy are not worthwhile
    or legitimate areas
    of investigation.
    As we will see, that is not the case.)
    </p>
    <p>
    For the hard scienes, Popper's answer to his question of
    "demarcation" was that a scientific theory for which,
    at least in principle, there was an empirical test
    that would "falsify" it.
    This is as opposed to the method of "looking for evidence".
    In Popper's view, finding evidence to corroborate a theory
    was easy and useless.
    If, during this search for evidence,
    the theory was never at risk,
    no amount of "confirming" evidence means anything.
    The more doctrinaire followers of Freud found
    vast amounts of evidence to confirm his theories,
    but in none of these tests was Freud's theory at risk.
    The kind of evidence they found confirmed Freud,
    but could not have refuted him,
    and therefore, from Popper's point of view,
    its corroborative value was zero.
    </p>
    <p>Einstein, on the other hand, put his theory at very serious risk
    in this prediction of the deflection of light in a 1919 eclipse.
    Einstein's theory was *falsifiable*,
    and falsifiability was the criterion of a hard science.
    <h2>What about the soft sciences?</p>
    <p>What about the "soft" fields of study -- politics,
    economics, philosophy, etc.
    Einstein's theory of relativity was falsifiable, and therefore
    hard science.
    But what about Einstein's view on scientific methods?
    No experiment could prove Holmes wrong or Einstein right,
    but surely whether or not these views are true is a useful
    and even necessary question.
    </p>
    <p>
    Some have tried maintained that,
    outside the hard sciences, there is no truth --
    that a question either lends itself to empirical testing,
    or it is "not even wrong".
    But Popper was never one of them.
    </p>
    <p>
    To understand how Popper adapted Einstein's methods to
    social science and philosophy, it is useful to kind in
    mind three things.
    First, even hardest of sciences has its soft edges.
    Every empirical test requires theory to interpret,
    and every empirical test can be wrong.
    </p>
    <p>
    Second, even if proponents of a theory decide to accept an empirical
    refutation,
    they can do so by modifying the theory,
    rather than abandoning it.
    If fact, Popper asserts,
    no theory should ever be completely abandoned,
    whatever the evidence against it.<footnote>
    TODO: Find a reference for this, or delete it.
    </footnote>
    </p>
    <p>
    Third, and most significant,
    some of the most necessary theories,
    are, by the nature "irrefutable" --
    There is no logical argument against them,
    and no empirical evidence can prove them wrong.
    </p>
    <p>
    How do you decide the truth of an irrefutable theory?
    Popper's answer is that this can only be done with reference
    to the problems you want the theory to solve.
    A theory which produces useful answers is more true,
    than one which does not.
    The economic theory of the physiocrats was that "all wealth comes from the land".
    Ignoring fishing, it is irrefutable -- it is possible to trace all wealth back
    to agriculture.
    The physiocrats theory seemed very helpful in the 18th century,
    when the "tracing" was not very hard
    -- most wealth came directly from agriculture.
    And the physiocrat's motto remains true in a pedantic and abstract sense.
    But it is not helpful for studying the economy,
    now that less than 2% of the population is employed in agriculture,
    and work in farming is so heavily mechanized that you could equally
    claim that all wealth comes from the manufacturing of machines,
    or from the consumption of energy,
    and all three claims would be irrefutable.
    </p>
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
    <p>Like Einstein's book, however,
    a timeline is history of science,
    not science.
    How does one "test" history of science?
    </p>
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
    <h2>Questions</h2>
    <p>
    Is the PEG algorithm being proposed a future,
    or does it have an implementation?
    Certainly, if necessary, alternatives may be proposed,
    but is it clear which features belong to which
    implementation or proposal?
    </p>
    <p>What claims of speed and time complexity are made?
    Is there a way of determining in advance of runtime how fast
    your algorithm will run?
    Or is the expectation of practical speed
    on an "implement and pray" basis?
    </p>
    <p>Does the proposed PEG algorithm match human parsing
    capabilities?
    If not, it is a claim for human exceptionalism,
    of a kind not usually accepted in modern computer science.
    How is it justified in this case.
    </p>
    </p>If a combination of PEG algorithms is advanced as the
    alternative to human parsing capabilities,
    can the alternatives be unified in the way that humans
    apparently are unifying the algorithms?
    <p>
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
