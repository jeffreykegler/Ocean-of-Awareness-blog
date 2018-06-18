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
      it was these capabilities which led to
      <a href="http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2018/05/fast_power.html">
      RD's
      triumph over the now-forgotten Irons algorithm.</a>
    </p>
    <p>
      Marpa, however, has a parse engine expressly redesigned<footnote>
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
    </p>
    <h2>A context-sensitive grammar</h2>
    <p>Marpa parses all LR-regular grammars in linear time,
    so the first challenge is to find a grammar
    that illustrates a
    <b>need</b> for procedural logic, even when Marpa is used.
    The following is the canonical example of a grammar that is
    context-sensitive, but not context-free:
    </p>
    <pre>
          a^n . b^n . c^n : n >= 1
    </pre>
    I will call this the "ABC grammar".
    It is a sequence of
    <tt>a</tt>'s,
    <tt>b</tt>'s, and
    <tt>c</tt>'s,
    in alphabetical order,
    where the character counts are all
    equal to each other and greater
    than one.
    </p>
    <p>The ABC "grammar" is really a counting problem more than
    a natural parsing problem,
    and parsing is not the fastest or easiest way to solve it.
    Three tight loops, with counters, would do the same job nicely,
    and would be much faster.
    But I chose the ABC grammar for exactly this reason.
    It <b>is</b> simple in itself,
    but it is tricky when treated as a parsing problem.<footnote>
    The ABC grammar, in fact,
    is not all that easy or natural to describe
    even with a context-sensitive phrase structure description.
    A solution is given on Wikipedia:
    <a href="https://en.wikipedia.org/wiki/Context-sensitive_grammar#Examples">
    https://en.wikipedia.org/wiki/Context-sensitive_grammar#Examples</a>.
    </footnote>
    </p>
    <p>
    In picking the strategy below,
    I opted for one that illustrates
    a nice subset of Marpa's procedural parsing capabilities.
    Full code is
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/csg">
    on-line<a>,
    and readers are encouraged to "peek ahead".
    </p>
    <h2>Step 1: the syntax</h2>
    <p>Our strategy will be to start with a context-free syntax,
    and then extend it with procedural logic.
    Here is the context-free grammar:
    </p>
    <pre><tt>
    lexeme default = latm => 1
    :default ::= action => [name,start,length,values]
    S ::= prefix ABC trailer
    ABC ::= ABs Cs
    ABs ::= A ABs B | A B
    prefix ::= A*
    trailer ::= C_extra*
    A ~ 'a'
    B ~ 'b'
    :lexeme ~ Cs pause => before event => 'before C'
    Cs ~ 'c' # dummy -- procedural logic reads <Cs>
    C_extra ~ 'c'
    </tt></pre>
    <p>The first line is boiler-plate:
    It turns off a default which was made pointless
    by a later enhancement to Marpa::R2.
    Marpa::R2 is stable, and backward-compatibility is
    a very high priority.
    <pre><tt>
    :default ::= action => [name,start,length,values]
    </tt></pre>
    <p>
    We will produce a parse tree.
    The second line defines its format --
    each node is an array whose elements are,
    in order,
    the node name, its start position,
    its length and its child nodes.
    </p>
    <pre><tt>
    S ::= prefix ABC trailer
    </tt></pre>
    <p>The symbol <tt>&lt;ABC&gt;</tt>
    is our "target" -- the counted
    <tt>a</tt>'s,
    <tt>b</tt>'s,
    and <tt>c</tt>'s.
    To make things a bit more interesting,
    and to make the problem more like a parsing problem instead of a counting problem,
    we allow a prefix of <tt>a</tt>'s
    and a trailer of <tt>c</tt>'s.
    </p>
    <pre><tt>
    ABC ::= ABs Cs
    </tt></pre>
    <p>We divide the
    <tt>&lt;ABC&gt;</tt> target into two parts:
    <tt>&lt;ABs&gt;</tt>, which contains the
    <tt>a</tt>'s,
    and <tt>b</tt>'s;
    and
    <tt>&lt;Cs&gt;</tt>, which contains
    the <tt>c</tt>'s.
    </p>
    <p>
    The string
    </p>
    <pre><tt>
    a^n . b^n
    </tt></pre>
    <p>
    is context free, so that we can handle it
    without procedural logic, as follows:
    </p>
    <pre><tt>
    ABs ::= A ABs B | A B
    </tt></pre>
    <p>
    The line above recognizes a non-empty string of
    <tt>a</tt>'s,
    followed by an equal number
    of <tt>b</tt>'s.
    </p>
    <pre><tt>
    prefix ::= A*
    trailer ::= C_extra*
    </tt></pre>
    <p>As stated above,
    <tt>&lt;prefix&gt;</tt>
    is a series of <tt>a</tt>'s and
    <tt>&lt;trailer&gt;</tt>
    is a series of <tt>c</tt>'s.
    </p>
    <pre><tt>
    A ~ 'a'
    B ~ 'b'
    </tt></pre>
    <p>Marpa::R2 has a separate lexical and syntactic phase.
    Here we define our lexemes.
    The first two are simple enough:
    <tt>&lt;A&gt;</tt> is the character "<tt>a</tt>"; and
    <tt>&lt;B&gt;</tt> is the character "<tt>b</tt>".
    </p>
    <pre><tt>
    :lexeme ~ Cs pause => before event => 'before C'
    Cs ~ 'c' # dummy -- procedural logic reads <Cs>
    C_extra ~ 'c'
    </tt></pre>
    <p>
    For the character "<tt>c</tt>",
    we need procedural logic.
    As hooks for procedural logic,
    Marpa allows a full range of events.
    Events can occur on prediction and completion of symbols;
    when symbols are nulled;
    before lexemes;
    and after lexemes.
    The first line in the above display
    declares a "before lexeme" event
    on the symbol
    <tt>&lt;Cs&gt;</tt>.
    The name of the event is "<tt>before C</tt>".
    </p>
    <p>The second line is a dummy entry,
    which is needed to allow the "<tt>before C</tt>"
    event to trigger.
    The entry says that
    <tt>&lt;Cs&gt;</tt> is a single character "<tt>c</tt>".
    This is false --
    <tt>&lt;Cs&gt;</tt> is a series of one or more
    <tt>c</tt>'s,
    which needs to be counted.
    But when
    the "<tt>before C</tt>" event triggers,
    the procedural
    logic will make things right.
    </p>
    <p>The third line defines
    <tt>&lt;C_extra&gt;</tt>, which
    is another lexeme for the character "<tt>c</tt>".
    We have two different lexemes for
    the character <tt>c</tt>, because we want some
    <tt>c</tt>'s (those in the target)
    to trigger events;
    and we want other
    <tt>c</tt>'s (those in the trailer)
    not to trigger events,
    but to be consumed by Marpa directly.
    </p>
    <h2>The procedural logic</h2>
    <p>
    At this point, we have solved part of the problem with context-free syntax,
    and set up a Marpa event named "<tt>before C</tt>",
    which will solve the rest of it.
    </p>
    <pre><tt>
    my $input_length = length ${$input};
    for (
        my $pos = $recce->read($input);
        $pos < $input_length;
        $pos = $recce->resume()
      )
    {
      </tt><b>... Process events ...</b><tt>
    }
    </tt></pre>
    <p>Processing of events takes place inside a Marpa read loop.
    This is initialized with a <tt>read()</tt> method,
    and is continued with a <tt>resume()</tt> method.
    The <tt>read()</tt> and <tt>resume()</tt> methods
    both return the current position
    in the input.
    If the current position is end-of-input, we are done.
    If not, we were interrupted by an event, which we
    must process.
    </p>
    <pre><tt>
    </tt><b>Process events</b><tt>

    EVENT:
      for (
	  my $event_ix = 0 ;
	  my $event    = $recce->event($event_ix) ;
	  $event_ix++
	)
      {
	  my $name = $event->[0];
	  if ( $name eq 'before C' ) {
	      </tt><b>... Process "before C" event ...</b><tt>
	  }
	  die qq{Unexpected event: name="$name"};
      }
    </tt></pre>
    <p>In this application, only one event can occur at any location,
    so the above loop is "overkill".
    It loops through the events, one by one.
    The <tt>event</tt> method returns a reference to an array
    of event data.
    The only element we care about is the event name.
    In fact, if we weren't being careful about error checking,
    we would not even care about the event name,
    since there can be only one.
    </p>
    <p>If, as expected, the event name is "<tt>before C</tt>",
    we process it.
    In any other case, we die with an error message.
    </p>
    <pre><tt>
    </tt><b>Process "before C" event</b><tt>

    my ( $start, $length ) = $recce->last_completed_span('ABs');
    my $c_length = ($length) / 2;
    my $c_seq = ( 'c' x $c_length );
    if ( substr( ${$input}, $pos, $c_length ) eq $c_seq ) {
	$recce->lexeme_read( 'Cs', $pos, $c_length, $c_seq );
	next EVENT;
    }
    die qq{Too few C's};
    </tt></pre>
    <p>This is the core part of our procedural logic,
    where we have a "<tt>before C</tt>" event.
    We must
    <ul>
    <li>determine the right number of <tt>c</tt> characters;</li>
    <li>check that the input has
      the right number of <tt>c</tt> characters;</li>
    <li>put together a lexeme to feed the Marpa parser; and</li>
    <li>return control to Marpa.</li>
    </ul>
    There is a lot going on,
    and some of Marpa's most powerful capabilities for assisting
    procedural logic are shown here.
    So we will go through the above display in detail.
    </p>
    <h3>Left-eidetic</h3>
    <pre><tt>
    my ( $start, $length ) = $recce->last_completed_span('ABs');
    my $c_length = ($length) / 2;
    </tt></pre>
    <p>Marpa claims to be "left-eidetic",
    that is, to have full knowledge of the parse so far,
    and to make this knowledge available to the programmer.
    How does a programmer cash in on this promise?
    <p>Of course, there is
    <a href="https://metacpan.org/pod/distribution/Marpa-R2/pod/Progress.pod">a fully general interface</a>,
    which allows you to go through the Earley tables and extract
    the information in any form necessary.
    But another, more convenient interface,
    fits our purposes here.
    Specifically,
    </p>
    <ul><li>we want to determine how many <tt>c</tt> characters we are looking for.</li>
    <li>How many <tt>c</tt> characters we are looking for depends
    on the number of
    <tt>a</tt> and <tt>b</tt> characters that we have already seen
    in the target.</li>
    <li>The <tt>a</tt> and <tt>b</tt> characters that we have already seen in the
    target are in the
    <tt>&lt;ABs&gt;</tt> symbol instance.</li>
    <li>So, what we want to know is the length of the
    most recent <tt>&lt;ABs&gt;</tt> symbol instance.</li>
    </ul>
    </p>
    <p>Marpa has a <tt>last_completed_span()</tt> method,
    and that is just what we need.
    This finds the most recent instance of a symbol.
    (If there had been more than one most recent instance,
    it would have found the longest.)
    The <tt>last_completed_span()</tt> method returns the start
    of the symbol instance (which we do not care about)
    and its length.
    The desired number of <tt>c</tt> characters,
    <tt>$c_length</tt>, is half the length of the
    <tt>&lt;ABs&gt;</tt> instance.
    </p>
    <h3>External parsing</h3>
    <pre><tt>
    my $c_seq = ( 'c' x $c_length );
    if ( substr( ${$input}, $pos, $c_length ) eq $c_seq ) { </tt><b>...</b><tt> }
    </tt></pre>
    <p>Marpa allows external parsing.
    You can pause Marpa, as we have done,
    and hand control over to another parser -- including
    another instance of Marpa.
    </p>
    <p>
    Here external parsing is necessary to make our parser
    context-sensitive,
    but the external parser does not have to be fancy.
    All it needs to do is
    some counting -- not hard,
    but something that a context-free grammar cannot do.
    </p>
    <p>
    <tt>$pos</tt> is the current position in the input,
    as returned by the <tt>read()</tt> or <tt>resume()</tt>
    method in the outer loop.
    Our input is the string referred to by <tt>$input</tt>.
    We just calculated <tt>$c_length</tt> as the number of
    <tt>c</tt> characters required.
    The above code checks to see that the required number of
    <tt>c</tt> characters is at <tt>$pos</tt> in the input.
    </p>
    <h3>Communicating with Marpa</h3>
    <pre><tt>
	$recce->lexeme_read( 'Cs', $pos, $c_length, $c_seq );
    </tt></pre>
    <p>
    Our external logic is doing the parsing,
    but we need to let Marpa know what we are finding.
    We do this with the <tt>lexeme_read()</tt> method.
    <tt>lexeme_read()</tt> needs to know what symbol we are reading
    (<tt>Cs</tt> in our case);
    and its value
    (<tt>$c_seq</tt> in our case).
    </p>
    <p>
    Marpa requires that
    every symbol be tied in some way to the input.
    The tie-in is only for error reporting,
    and it can be hack-ish or completely artificial,
    if necessary.
    In this application, our symbol instance is tied into
    the input in a very natural way --
    it is the stretch of the input that we compared
    to <tt>$c_seq</tt> in the display before last.
    We therefore tell Marpa
    that the symbol is at <tt>$pos</tt> in the input,
    and of length <tt>$c_length</tt>.
    </p>
    <h3>Passing control back to Marpa</h3>
    <pre><tt>
	next EVENT;
    </tt></pre>
    <p>
    External parsing can go on quite a long time.
    In fact, an external parser <b>never</b> has to hand
    control back to Marpa.
    But in this case, we are done very quickly.
    </p>
    <p>
    We ask for the next iteration of the <tt>EVENT</tt>
    loop.
    (In this code,
    there will not be a next iteration, unless there is an error.)
    Once done, the <tt>EVENT</tt> loop will hand control
    over to the outer loop.
    The outer loop will call the <tt>resume()</tt>
    method to return control back to Marpa.
    </p>
    <h2>The code, comments, etc.</h2>
    <p>The full code for this example is 
    <a href="https://github.com/jeffreykegler/Ocean-of-Awareness-blog/tree/gh-pages/code/csg">
    on-line<a>.
      There is a lot more to Marpa, including
      more facilities for adding procedural logic to your Marpa parsers.
      To learn more about Marpa,
      a good first stop is the
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
