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
    <h2>A Practical use of infinite Lookahead</h2>
    <p>Infinite lookahead, despite how it may sound,
    is called for by many grammars of practical interest --
    the original research into it was motivated by practical interest.<footnote>
    TODO.  Reference LRR paper, my blog post on it,
    and my blog post on LRR and Haskell.
    </footnote>
    But a very compact example that does not seem artificial can be hard to find.
    In my work on the Hoon language, I have just stumbled on a very nice one.
    </p>
    <p>Recently, the Urbit community has been generously supporting
    my work on Marpa parsing,
    and the Hoon language is part of the Urbit project.
    Urbit is an effort to return control of the Internet
    experience to the individual user.
    </p>
    <p>
    The original Internet and it's predecessors were cosy places.
    Users controlled their experience and authority was so light you
    could forget it was there , but so adequate you could forget why it
    was necessary.   What you did remember was the feeling of entering
    into a "brave new world".
    </p>
    <p>
The access to information afforded by the modern Internet makes our
early pure wonder seems laughable, but the cost of it has been a transfer
of power which should be frightening. We have handed authority over to
servers run by entities which have their own interests, interests they
pursue with increasing single-mindedness.  And while in the early days,
we relied on the Internet for a portion of our intellectual lives, we
now depend on it for our financial and social lives as well.  Currently,
the server-sphere can be a hostile  place.  Going forward it could become
a theater of war.
    </p>
    We could try to solve this problem by running our own servers.
    But this is a lot of work, and only leaves us in touch with those
    willing and able to do that.  In practice, nobody seems to find
    this worthwhile.
    </p>
    <p>
Urbit seeks to solve these problems with hassle-free personal
servers.  These are incorruptable because they are also journaling
databases. Typically these servers will be run as in the cloud.  In their
present form, they run on top of Unix and UDP.
    </p>
    <p>
    To implement its personal servers, Urbit chose to deal the code
    bloat and other issues of the current Internet by rewriting
    from scratch.   They start with a new machine language for a
    VM, called Nock.
    Machine languages have evolved -- originally the
    programmer was expected to write their own memory caching logic.
    In keeping with the times, Nock does garbage collection as well, and
    its integers are arbitrary precision.
    Nock treats all data and code
    as integers or trees, and has a distinct LISP flavor.
    Like traditional
    machine language, Nock cannot be written directly.
    Traditionally, you had to toggle machine language in physically
    or, more commonly, write it indirectly in assembler or in
    solme higher-level language.
    In Nock's case, you have to write it using Hoon.
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
