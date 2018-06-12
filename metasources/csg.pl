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
Marpa and procedural parsing
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>Procedural parsing</h2>
    <p>Marpa is an Earley-based parser,
      and Earley parsers are typically not good at procedural parsing.
      Many programmers are used to recursive descent (RD),
      which has been state-of-the-art in terms of
      its procedural programming capabilities --
      it was these capabilities which led to RD's
      triumph over the now-forgotten Irons algorithm.<footnote>
      TODO.
      </footnote>
    </p>
    <p>
      Marpa, however, has parse engine expressly redesigned<footnote>
      To handle procedural logic well,
      an Earley engine needs to complete its Earley sets
      in strict order --
      that is, Earley set <tt>N</tt>
      cannot change after work on Earley set <tt>N+1</tt>
      has begun.
      I have not looked at every Earley parse engine,
      and some may have had this strict-sequencing property.
      And many of the papers are agnostic about the order
      of operations.
      But Marpa is the first Earley parser to recognize
      and exploit strict-sequencing as a feature.
      </footnote>
      to handle procedural logic well.
      In fact, Marpa is <b>better</b> at procedural logic
      than RD.
      I will show this with an example.
    </p>
    <h2>A context-sensitive grammar</h2>
    <p>RD, to be sure, natively only handles LL(1) grammars,
    while Marpa parses all LR-regular grammars in linear time.
    So Marpa <b>needs</b> procedural logic much less than RD.
    As an example of a grammar for which Marpa does
    require procedural logic, we'll pick the canonical example
    of a context-sensitive, but not context-free grammar:
    </p>
    <pre>
          a^n . b^n . c^n : n >= 1
    </pre>
    This is a sequence of
    <tt>a<tt>'s,
    <tt>b<tt>'s, and
    <tt>c<tt>'s,
    in alphabetical order,
    where the character counts are all
    equal to each other and greater
    than one.
    </p>
    <h2>Comments, etc.</h2>
    <p>TODO<footnote>
    One objection to the use of procedural logic to describe the ABC
    grammar is that the mix of procedural and syntactic description is unnatural.
    This is true, but hack-ish as the Marpa description is,
    I think the reader will find it clearer than its purely syntactic
    "native" description as a CSG:
    <a href="https://en.wikipedia.org/wiki/Context-sensitive_grammar#Examples">
    https://en.wikipedia.org/wiki/Context-sensitive_grammar#Examples</a>.
    </footnote>.
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
