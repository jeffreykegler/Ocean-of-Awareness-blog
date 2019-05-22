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
Infinite Lookahead and Ruby Slippers
<html>
  <head>
  </head>
  <body>
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>About this post</h2>
    <p>This post presents a compact, practical example which
    nicely illustrates the need for both infinite lookahead
    and Ruby Slippers parsing.
    Infinite lookahead 
    is required by any syntax which might of arbitrary length,
    but whose structure is not certain until the end.
    Human language has a lot of examples of this<footnote>
    One example is the sentence "The horse raced past the barn fell".
    The subclause "raced past the barn" could be anything,
    and therefore arbitrarily long.
    In isolation, this sentence may not seem unnatural,
    a contrived "garden path".
    But if you imagine it in answer to the question, "Which horse fell?",
    the construct becomes quite natural.
    When the expectations are balanced,
    humans parse these in the same way that Marpa does -- by keeping track
    of both possibilities until the end,
    and only then deciding.
    </footnote>
    and, labor as computer language designers might to avoid it,
    the need for infinite lookahead keeps popping up 
    in desirable syntaxes.<footnote>
    Ref to Haskell post.
    </footnote>
    I have just stumbled on a very nice compact example of this.
    </p>
    <h2>About Urbit</h2>
    <p>The example of this post arises in the context of a language called Hoon,
    which is part of the Urbit project.
    (The Urbit community has, generously, been supporting my work on Hoon.)
    Urbit is an effort to return control of the Internet
    experience to the individual user.
    </p>
    <p>
    The original Internet and its predecessors were cosy places.
    Users controlled their experience.
    There was authority, but it was so light you
    could forget it was there,
    and so adequate to its task that you could forget why it
    was necessary.
    What we old timers do remember of the early Internet was the feeling of entering
    into a "brave new world".
    </p>
    <p>
The Internet has grown in extent beyond previous imaginings,
and the pure wonder of decades ago seems ridiculous.
But the price has been a shift
of power which should be no laughing matter.
Control of our Internet experience now resides in
servers,
run by entities which make no secret of having their own interests.
Less overt, but increasingly obvious, is the single-mindedness with which they pursue
those interests.
</p>
<p>
And the stakes have risen.
In the early days,
we used on the Internet as a supplement in our intellectual lives.
Today, we depend on it for our financial and social lives.
Today, the server-sphere can be a hostile  place.
Going forward it may well become a theater of war.
    </p>
    We could try to solve this problem by running our own servers.
    But this is a lot of work, and only leaves us in touch with those
    willing and able to do that.  In practice, this seems to be nobody.
    </p>
    <p>
Urbit seeks to solve these problems with 
hassle-free personal servers, called urbits.
Urbits are journaling databases, so they are incorruptable.
To make sure they can be run anywhere in the cloud,
they are based on a tiny virtual machine.
To keep urbits compact and secure,
Urbit takes on code bloat directly:
Urbit uses a totally original design from a clean slate --
a new protocol stack, and a new VM called Nock.<footnote>
In their present form, urbits run on top of Unix and UDP.
</footnote>
    </p>
    <h2>About Hoon</h2>
    <p>
    The "machine language" is trees of arbitrary precision integers.
    The integers can be interpreted as strings, floats, etc.,
    as desired.
    And the trees can be interpreted as lists, giving Nock a distinct LISP flavor.
    Nock also does its own garbage collection.
    <footnote>
    Garbage collection and arbitrary precision may not too high-level
    for something considered a "machine language",
    but our concepts evolve.
    The earliest machine languages required programmers to
    do their own memory caching and create their own floating
    point representations,
    both things we now regard as much too low-level for software
    to deal with directly.
    </footnote>
    </p>
    <p>
    Traditionally, you had to toggle machine language in physically
    or, more commonly, write it indirectly,
    in assembler or using some higher-level language, like C.
    Like traditional
    machine language, Nock cannot be written directly.
    Hoon is Urbit's equivalent of C -- it is Urbit's
    "close to the metal" higher level language.
    </p>
    <p>
    Not that Hoon looks much like C,
    or for that matter anything else you've ever seen.
    This is a Hoon program that takes an integer argument,
    call it <tt>n</tt>,
    and returns the first <tt>n</tt> counting numbers:
    <pre><tt>
    |=  end=@                                               ::  1
    =/  count=@  1                                          ::  2
    |-                                                      ::  3
    ^-  (list @)                                            ::  4
    ?:  =(end count)                                        ::  5
      ~                                                     ::  6
    :-  count                                               ::  7
    $(count (add 1 count))                                  ::  8
    </tt></pre>
    </p>
    <p>
    Hoon comments begin with a "<tt>::</tt>" and run until the next
    newline.
    The above Hoon sample uses comments to show line numbers.
    For the sake of our example, comments are the only Hoon syntax we will talk about.
    (For those who want to learn more about Hoon,
    <a href="https://urbit.org/docs/learn/hoon/">there is a tutorial</a>.)
    </p>
    <p>
    </p>
    <h2>About Hoon comments</h2>
    <p>
    In the basic Hoon syntax, multi-line comments are free-form.
    In practice, there are strict, if complex, conventions.
    In the simplest case, a comment must precede the code it
    describes, and be at the same indent.
    These simple cases are called "pre-comments".<footnote>
    This post attempts to follow standard Hoon terminology, but
    for the details of Hoon's whitespace conventions,
    there is settled terminology,
    and I have invented terms as necessary.
    The term "pre-comment" is one of those inventions.
    </footnote>
    For example, this code contains a pre-comment:
    <pre><tt>
	  :: pre-comment 1
	  [20 (mug bod)]
    </tt></pre>
    <p>
    But some code falls into sequences, and sequences are allowed
    "inter-comments".
    In sequences, the pre-comments are indented to match the elements
    of the sequence,
    but inter-comments are indented to match the "keyword" of the sequence.
    The following code has both pre-commments and inter-comments.
    The intercomments are indented to match the "keyword" digraph: <tt>:~</tt>.
    (Hoon's keyword digraphs are called "runes".)
    </p>
    <pre><tt>
      :~  [3 7]
      ::
	  :: pre-comment 1
	  [20 (mug bod)]
      ::
	  :: pre-comment 2
	  [2 yax]
      ::
	  :: pre-comment 3
	  [2 qax]
    ::::
    ::    :: pre-comment 3
    ::    [4 qax]
      ::
	  :: pre-comment 4
	  [5 tay]
      ==
    </tt></pre>
    <p>Note that the inter-comments in the above, are empty.
    They are called "breathing comments", and serve to separate,
    and give some air between, elements of a sequence.
    </p>
    <p>
    Comments can occur at the far left margin -- column 1.
    These are called meta-comments, because they are allowed
    to be outside the syntax structure.
    One common use for meta-comments is "commenting out" code.
    Note in the above display, the <tt>[4 qax]</tt> and its
    associated comments are commented out using meta-comments.
    </p>
    <p>Lastly, there are "staircase comments", which are used
    to indicate the larger structure of Hoon sequences and other
    code.
    For example,
    <pre><tt>
    ::                                                      ::
    ::::  3e: AES encryption  (XX removed)                  ::
      ::                                                    ::
      ::
    ::                                                      ::
    ::::  3f: scrambling                                    ::
      ::                                                    ::
      ::    ob                                              ::
      ::
    </tt> </pre>
    <p>
    Rules
    <ul>
    <li>Outside of a sequence, inter-comments and pre-comments
    are the same thing, and are indented the same as the code
    they precede.
    </li>
    <li>Inter-comments, when distinct from pre-comments,
    must precede them.
    </li>
    <li>Staircases can only occur as inter-comments.
    An inter-comment can contain more than one staircase,
    but if any staircase occurs in an inter-comment,
    the whole inter-comment is considered to be a set
    of staircases.
    </li>
    <li>Meta-comments can occur anywhere,
    but classifying a comment as a meta-comment is a last resort --
    if a comment can be considered a pre-comment or an inter-comment,
    then that is how it is classified.
    </li>
    </ul>
    <p>Some of the rules are motivated by a future Hoon tool,
    <tt>hoonfmt</tt>, which will reformat Hoon in much the same way
    as <tt>perltidy</tt> reformats Perl, or <tt>indent</tt>
    reformats C today.
    </p>
    </p>
    <p>
    The native compiler allows Hoon comments to be free-form
    but, as the above suggests, in practice Hoon comments are
    expected to follow certain conventions.
    </p>
    <p>
    My current work is on a Marpa-powered tool to enforce Hoon's whitespace
    conventions.
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
