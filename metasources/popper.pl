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
      It is not without its critics.
      Many of them accuse the timeline of lack of objectivity or of bias.
      </p>
      <p>
      Einstein assumed his reader's idea of methods of proper investigation,
      in science as elsewhere,
      would be similar to those Conan Doyle's Sherlock Holmes.
      I will follow Einstein's lead in starting there.
    </p>
    <p>
      If you look at the deduction recorded in the Holmes' canon,
      you see often involve <b>a lot</b>
      of theorizing, and more than a little outright speculation.
      To make it a matter of significance what the dogs in "Silver Blaze" did in the night,
      Holmes needs a theory of canine behavior,
      and Holmes' theory sometimes outpaces its pack of facts by a considerable distance.
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
    some very simple experiments.
    The account will be boring
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
    <h2>Commiting one's own crime</h2>
    <p>If then,
    we must commit the crime of theorizing before the facts,
    where does out theory come from?
    </p>
    <blockquote>
    In the case of planets moving around the sun
    it is found that the system of mechanics works
    splendidly.
    Nevertheless we can well imagine that another system,
    based on different assumptions,
    might work just as well.
    <br><br>
    Physical concepts are free creations
    of the human mind, and are not,
    however, it may seem,
    uniquely determined by the external world.
    In our endeavor to understand reality
    we are somewhat like a man trying
    to understand the mechanism of a closed watch.
    He sees the face and the moving hands,
    even hears its ticking,
    but he has no way of opening the case.
    If he is ingenious
    he may form some picture of a mechanism
    which could be responsible
    for all the things he observes,
    but he may never be quite sure
    his picture is the only one
    which could explain his observations.
    He will never be able
    to compare his picture with the real mechanism
    and he cannot even imagine the possibility
    or the meaning of such a comparison.
    But he certainly believes that,
    as his knowledge increases,
    his picture of reality will become
    simpler and simpler
    and will explain a wider and wider range
    of his sensuous impressions.
    He may also be believe in the existence
    of the ideal limit of knowledge
    and that it is approached
    by the human mind.
    He may call this ideal limit
    the objective truth. -- Einstein and Infeld<footnote>
    P. 31.
    See also Einstein, <cite>Ideas and Opinions</cite>, p. 272.
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
        Einstein and Infeld, p. 78.
      </footnote>
    </blockquote>
    <blockquote>
    A false theory may be as great an achievement as a true one.
    And many false theories have been more helpful in our search
    for truth than some less interesting theories which
    are still accepted.<footnote>
    Popper, p. 190.
    </footnote>
    </blockquote>
    <p>True, everyday thinking and the softer sciences often
    trade in concepts too "soft" to be proven by experiment.
    But even theories in the hard sciences are "underdetermined" --
    multiple theories will fit the same evidence.
    <blockquote>
    [ Insert some E quote about underdetermination. ]
    </blockquote>
    In fact, if the science is "hard",
    a theory in it is eventually going to be proven to be false --
    the best that can happen is that,
    like Newton's physics, it will be shown to be an important
    subcase of a larger theory.
    <blockquote>
    [ Insert some E quote about all theories being false.
    "Highway" quote here?
    Popper "False theory" quote here?
    ]
    </blockquote>
    </p>
    <p>So, given multiple theories which explain similar evidence,
    how do we choose among them?
    <blockquote>
    [ E on "simple" versus "wide in application".
    Popper on usefulness. ]
    </blockquote>
    </p>
    <h2>The method of the "Timeline"</h2>
    The historiography of my <cite>Timeline</cite> certainly takes a
    definite point of view.
    In its original version it was, in fact, essentially a history of
    the inspirations for my work in Earley/Leo parsing,
    and many events important in mainstream parsing
    received little mention.
    That a history with such a non-traditional focus was so popular
    was, I hope, in part due to the merits of that focus,
    but I know it was also a product of desperation for
    anything approaching a coherent accounts of this very important
    area of computer science.
    </p>
    <p>In response to the larger audience the <cite>Timeline</cite>
    attracted, later versions broadened the focus considerably.
    Many algorithms
    received had received only glancing mention in the <cite>Timeline</cite>,
    because they had not been important in my work.
    <cite>Timeline 3.1</cite> tries to include 
    all algorithms that have been important in mainstream parsing practice,
    including some which had little or no influence on my work.
    The parsing of arithmetic expressions,
    for example,
    is trivial in the Earley/Leo context,
    and so receives little mention in the original <cite>Timeline</cite>.
    But arithmetic expressions are at the borderline of power
    for traditional approaches,
    and their parsing is a crucial motivation for the authors of these algorithms.
    So <cite>Timeline 3.1</cite> they became a recurring theme,
    coming back for detailed examination time and time again.
    </p>
    <p>
    But the basic point of view taken by my <cite>Timeline</cite>
    has not wavered.
    Emphases
    include Chomskyan over non-Chomskyan parsing, 
    more general approaches over less general approaches,
    linear and quasi-linear approaches over slower approaches,
    non-statistical approaches over statistical approaches,
    and programming applications over NLP applications.
    For each and every one of these emphases,
    there is serious work,
    not just of historical interest,
    but current,
    that takes the opposite approach.
    In emphasizing Earley parsing over its competitors,
    my approach was and remains unusual.
    In emphasizing the Leo lineage within Earley parsing,
    my approach was for many years literally unique.
    </p>
    <h2>Let's get practical</h2>
    <p>Let's see what the "objectivity" that I claim for my timeline means in
    practice.
    How would you effectively "critique" <cite>Timeline</cite>?
    </p>
    <p>I maintain that you certainly can effectively critique it,
    otherwise my claim of objectivity is false.
    But some of the obvious approaches will not work.
    If you simply "packrat" in new, unabsorbed, material,
    you make the <cite>Timeline</cite> less effective for any purpose.<footnote>
    As an aside,
    while on the whole <cite>Timeline 3.1</cite> is superior to the original
    version, something was lost by adding all the new material.
    Timeline 1.0 was shorter, and its single-minded focus gave it (in its author's
    modest opinion) a narrative power lost in the more broadly informed
    Timeline 3.1.
    </footnote>
    If it happens to gore a favorite ox,
    this may produce a sense of justice, or at least relief,
    but it is hard to muddying the water in this way advances the cause of historiographic truth.
    </p>
    <p>To counter an effective use of viewpoint,
    you must make a more effective use of viewpoint.
    In the context of parsing history, you could vary any of the emphases in <cite>Timeline</cite>,
    but I will focus on the choice of an algorithm to emphasize.
    </p>
    <h2>The Forever Five</h2>
    <p>Recall<footnote>
    TODO</footnote>
    that the goal is problem-solving.
    A historiography is better if it solves more problems than another.
    What problems need solving,
    and what weight to give them,
    varies from programmer to programmer,
    and from time to time.
    This emphasis on "problems" is what makes computer science,
    one of the "soft sciences",
    albeit one which depends heavily on the hard sciences.
    </p>
    <p>My studies have left me to conclude that believe that five algorithms
    are of permanent significance,
    in that there is a set of practical problems which each one solves in
    a way that none of the other four can match.
    The "Forever Five" are regular expressions, recursive descent, PEG, Earley/Leo and Sakai's
    algorithm.<footnote>
    Three quibbles:
    Regular expressions do not find structure,
    so pedantically they are recognizers,
    not parsers.
    Recursive descent is technique for creating a family of algorithms,
    not an algorithm.
    The algorithm first described by Sakai is more commonly
    called CYK, from the initials of three other researchers who re-discovered
    it over the years.
    </footnote>
    Earley/Leo is the focus of my <cite>Timeline</cite>, so that an effective
    critique could be a parsing historiography centering on any other of the other four.
    </p>
    <p>For example, of the five, regular expressions are the most limited in parsing power.
    On the other hand, of the next five parsing problems you encounter,
    four are probably handled quite nicely by regular expressions.
    Good implementations of regular expressions are widely available.
    Almost everything you want to know about a regular
    expression is decidable in reasonable time.
    And, for speed, they are literally unbeatable -- if a parsing problem is a
    regular expression, no other algorithm will beat a dedicated regular expression
    engine for parsing it.
    </p>
    <p>Could a <cite>Timeline</cite> competitor be written which
    centered on regular expressions?
    Certainly.
    And if immediate usefulness to the average programmer is the criteria
    (and it's a very good one),
    then the <cite>Regular Expressions Timeline</cite> would certainly give
    my timeline a run for the money.
    </p>
    <h2>What about a PEG Timeline?</h2>
    <p>
    The immediate impetus for this article was a very collegial inquiry
    from someone whose main interest was PEG.
    Could a <cite>PEG Timeline</cite> challenge mine?
    Again, very certainly.
    </p>
    <p>Because there are at least some
    problems for which PEG is superior to everything else,
    my own Earley/Leo approach not excepted.
    As one example, PEG,
    sheared of the overpromising in its
    writeups,
    could be an more powerful alternative to regular expressions.
    </p>
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
    <h2>[ QUARRY ]</h2>
    <blockquote>
    The whole of science is nothing
    more than a refinement of everyday thinking.
    It is for this reason that the critical thinking
    of the physicist cannot possibly be restricted to
    the examination of the concepts of his own
    specific field.
    He cannot proceed without considering critically
    a much more difficult problem,
    the problem of analyzing the nature of everday
    thinking.
    <footnote>
    E:I&0, p 290.
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
    <p>[Popper quote?]</p>
    <p>It is a myth, as we have seen,
    that objectivity means taking the "view from nowhere".
    "Objectivity" means that something is not just dependent on my 
    own viewpoint, but that it can be criticized from a shared
    perspective.<footnote>
    Readers concerned with these matters may note that I use
    "objective" to mean "intersubjective".
    This follows Popper and,
    for the reader not concerned with technical philosophical points,
    I think this is best.
    For others, I, with Popper, regard the intersubjective is as close
    to the objective as we are going to get, certainly in the "soft"
    fields of study.
    Whether this means that intersubjective and objective are in fact
    the same thing takes us far away from computer science and
    deep into metaphysics.
    </footnote>
    </p>
    <p>
    The "view from nowhere" is <b>not</b> objective,
    because it is not free of a viewpoint --
    it hides its viewpoint.
    To the extent a viewpoint remains concealed, the reader
    is hindered from critique the viewpoint or its results.
    To the extent a reader is not free to accurately critique
    something, it cannot be a shared "object" between author
    and reader.
    Objectivity requires viewpoint.
    </p>
    <comment>FOOTNOTES HERE</comment>
  </body>
</html>
