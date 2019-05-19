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
A Practical use of infinite Lookahead
<html>
  <head>
  </head>
  <body>
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>About this post</h2>
    <p>Infinite lookahead may not sound like a practical requirement, but it is.
    The original research into it was motivated by practical interest.<footnote>
    TODO.  Reference LRR paper, my blog post on it,
    and my blog post on LRR and Haskell.
    </footnote>
    And, despite the fact that language writers have trained themselves to work
    around it, the need keeps popping up.<footnote>
    Ref to Haskell post.
    </footnote>
    I have just stumbled on a very nice compact example of this.
    </p>
    <h2>About Urbit</h2>
    <p>Recently, the Urbit community has been generously supporting
    my work on Marpa parsing.
    Urbit is an effort to return control of the Internet
    experience to the individual user.
    </p>
    <p>
    The original Internet and it's predecessors were cosy places.
    Users controlled their experience.
    There was authority, but it was so light you
    could forget it was there,
    and so adequate to its task that you could forget why it
    was necessary.
    What we old timers do remember of the early Internet was the feeling of entering
    into a "brave new world".
    </p>
    <p>
The modern Internet offers an access to information that
makes the pure wonder of decades ago seems ridiculous.
The cost of it has been a transfer
of power which should be no laughing matter.
Control of our Internet experience now resides in
servers,
run by entities which make no secret of having their own interests.
Less open, but increasingly obvious, is the single-mindedness with which they pursue
those interests.
</p>
<p>
And the stakes have risen.
In the early days,
we used on the Internet as a supplement in our intellectual lives.
Today depend on it for our financial and social lives.
Today, the server-sphere can be a hostile  place.
Going forward it may well become a theater of war.
    </p>
    We could try to solve this problem by running our own servers.
    But this is a lot of work, and only leaves us in touch with those
    willing and able to do that.  In practice, this seems to mean nobody.
    </p>
    <p>
Urbit seeks to solve these problems with urbits:
hassle-free personal servers.
Urbits are journaling databases, so they are incorruptable.
To make sure they can be run anywhere in the cloud,
they are based on a tiny virtual machine.
To keep urbits compact and secure,
Urbit takes on code bloat directly,
it is a totally original design from a clean slate --
new protocols,
and a new stack.
    </p>
    <h2>About Hoon</h2>
    <p>
    In their present form, urbits run on top of Unix and UDP.
    Urbit's new VM is called Nock.
    Its "machine language" is called Nock.
    Machine languages have evolved -- modern machine languages
    incorporate memory caching,
    something the first programmers had to do on their own.
    Time marches on, and Nock also has garbage collection
    and arbitrary precision integers.
    In Nock, all data and code is a "noun",
    and a noun is either an integer or a tree.
    This gives Nock a distinct LISP flavor.
    </p>
    <p>
    Like traditional
    machine language, Nock cannot be written directly.
    Traditionally, you had to toggle machine language in physically
    or, more commonly, write it indirectly,
    in assembler or using some higher-level language, like C.
    <p>Hoon is Urbit's equivalent of C -- it is Urbit's
    "close to the metal" higher level language.
    Not that Hoon looks much like C,
    or for that matter anything else you've ever seen.
    This is a Hoon program that takes an integer argument,
    call it <tt>n</tt>
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
    We will not learn much Hoon in this post.
    All we are interesting in, in fact, are Hoon's comments.
    Hoon comments begin with a "<tt>::</tt>" and run until the next
    newline.
    The above Hoon sample uses comments to show line numbers.
    (For those who want to know more about Hoon,
    <a href="https://urbit.org/docs/learn/hoon/">there is a tutorial</a>.)
    </p>
    <p>
    </p>
    <h2>About Hoon comments</h2>
    <p>For our example, we are interested in Hoon's multi-line Hoon comments.
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
