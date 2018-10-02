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
Measuring language popularity
<html>
  <head>
  </head>
  <body style="max-width:850px">
    <!--
      marpa_r2_html_fmt --no-added-tag-comment --no-ws-ok-after-start-tag
      -->
    <h2>How to measure popularity</h2>
    <p>
      <a href="https://github.com/github/linguist">Github's
        linguist</a>
      is seen as the most trustworthy tool
      for estimating language popularity<footnote>
	This github repo for <tt>linguist</tt> is <a href=
	"https://github.com/github/linguist/"
	>https://github.com/github/linguist/</a>.
      </footnote>,
      in large part because it reports its result as
      the proportion of lines of code in a very large dataset,
      instead of web hits or searches.<footnote>
        The code percentages reported by
        <tt>linguist</tt>
        are based on blob sizes --
        line counts are not reliable for whole repositories:
        <a href="https://github.com/github/linguist/issues/3131">Github linguist issue #1331</a>,
        accessed 1 October 2018.
        As examples, see
        <a href="https://techcrunch.com/2018/09/30/what-the-heck-is-going-on-with-measures-of-programming-language-popularity/">
          Jon Evan's
          <cite>Techcruch</cite>
          article</a>;
	  and <a href=
	  "https://www.benfrederickson.com/ranking-programming-languages-by-github-users/"
	  >Ben Fredickson's project</a>.
	  The Github API's <a href=
	  "https://developer.github.com/v3/repos/#list-languages"
	  >command for listing languages</a> report its results in bytes,
	  suggesting that it is the sum of blob sizes.
	  And some Github-based measures of popularity seem to be even more crude that this --
	  they count entire repos as being in the repo's primary language.
      </footnote>
      It is ironic, in this context,
      that
      <tt>linguist</tt>
      avoids looking at the code,
      preferring to use
      metadata -- file name and the vim and shebang lines.
      Scanning the actual code is <tt>linguist</tt>'s last resort.<footnote>
        <tt>linguist</tt>'s methodology is described in its README.md (
        <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md">
          permalink as of 30 September 2018</a>).
      </footnote>
    </p>
    <p>How accurate is this?
      For files that are mostly in a single programming language,
      currently the majority of them,
      <tt>linguist</tt>'s method are probably very accurate.
    </p>
    <p>But literate programming often requires mixing languages.
      It is perhaps an extreme example,
      but much of the code used in this blog post
      comes from a Markdown file, which contains both C and Lua.
      This code is "untangled" from the Lua by ad-hoc scripts<footnote>
        This custom literate programming system is not documented or packaged,
	but those who cannot resist taking a look can find the Markdown
	file it processes <a href=
	"https://github.com/jeffreykegler/Marpa--R3/blob/f16ef5798986da69fa8b437edc3930ce2cebd498/cpan/kollos/kollos.md"
	>here</a>,
	and its own code <a href=
	"https://github.com/jeffreykegler/Marpa--R3/blob/f16ef5798986da69fa8b437edc3930ce2cebd498/cpan/kollos/miranda">
	here</a>
	(permalinks accessed 2 October 2018).
      </footnote>.
      In my codebase,
      <tt>linguist</tt>
      indentifies this code simply
      as Markdown.<footnote>
        For those who care about getting
        <tt>linguist</tt>
        as
        accurate as possible.
        there is a workaround:
        the
        <tt>linguist-language</tt>
        git attribute.
        This still requires that each blob be 
	reported as containing lines of only one language.
      </footnote>
      <tt>linguist</tt>
      then ignores it,
      as it does all documentation files.<footnote>
        For the treatment of Markdown, see
        <tt>linguist</tt>
        <a href="https://github.com/github/linguist/blob/8cd9d744caa7bd3920c0cb8f9ca494ce7d8dc206/README.md#my-repository-isnt-showing-my-language">README.md</a>
        (permalink accessed as of 30 September 2018).
      </footnote>.
    </p>
    <p>Currently, this kind of homegrown
      literate programming may be so rare
      that it is not worth taking into account.
      But if literate programming becomes more popular,
      that trend might well slip under
      <tt>linguist</tt>'s radar.
      And even those with a lot of faith in
      <tt>linguist</tt>'s numbers should be happy to
      know they could be confirmed by more careful methods.
    </p>
    <h2>Token-by-token versus line-by-line</h2>
    <p><tt>linguist</tt> avoids reporting results based looking at the code,
    because careful line counting for multiple languages
      cannot be done with traditional parsing methods.<footnote>
        Another possibility is a multi-scan approach -- one
        pass per language.
        But that is likely to be expensive --
        at last count there were 381 langauges in
        <tt>linguist</tt>'s
        database.
        Worse, it won't solve the problem --
        "liberal" recognition even of a single language
        requires more power than available from
        traditional parsers.
      </footnote>
      To do this, a parser must be able to handle ambiguity in several forms --
      ambiguous parses, ambiguous tokens, and overlapping variable-length tokens.
    </p>
    <p>
      The ability to deal with
      "overlapping variable-length tokens" may sound like a bizarre requirement,
      but it is not.
      Line-by-line languages (BASIC, FORTRAN, JSON, .ini files, Markdown)
      and token-by-token languages (C, Java, Javascript, HTML)
      are both common,
      and even today commonly occur in the same file (POD and Perl,
      Haskell's Bird notation, Knuth's CWeb).
      Deterministic parsing can switch back and forth,
      though at the cost of some very hack-ish code.
    </p>
    <p>
      For careful line counting,
      you need to parse line-by-line and token-by-token
      simultaneously.
    </p><p>
      Consider this example:
    </p>
    <pre><tt>
    int fn () { /* for later
\begin{code}
   */ int fn2(); int a = fn2();
   int b = 42;
   return  a + b; /* for later
\end{code}
*/ }
    </tt></pre>
    <p>An artificial example suffices,
      but a reader might imagine this code is part of a test case using code
      pulled from a LaTeX file.
      The programmer wanted to indicate the copied portion of code,
      and did so by commenting out its original LaTeX delimiters.
      It's not pretty, but GCC compiles this code without warnings.
    </p>
    <p>It is not really the case that LaTeX is a line-by-line language.
      But in literate programming systems<footnote>
      For example, these line-alignment requirements match 
      those in
      <a href=
      "https://www.haskell.org/onlinereport/haskell2010/haskellch10.html"
      >Section 10.4</a> of the 2010 Haskell Language Report.
      </footnote>,
      it is usually required that the
      <tt>\begin{code}</tt>
      and
      <tt>\end{code}</tt>
      delimiters begin at column 0,
      and that the code block between them be a set of whole lines,
      so, for our purposes in this post,
      we can treat LaTeX as line-by-line.
      For LaTeX, our parser finds
    </p><pre><tt>
  L1c1-L1c29 LaTeX line: "    int fn () { /* for later"
  L2c1-L2c13 \begin{code}
  L3c1-L5c31 [A CODE BLOCK]
  L6c1-L6c10 \end{code}
  L7c1-L7c5 LaTeX line: "*/ }"<footnote>
  Adapted from
  <a href=
  "https://github.com/jeffreykegler/Marpa--R3/blob/08fa873687130fcfbe199a5f573375ad11322f3a/pub/varlex/idlit_ex2.t#L83"
  >test code in Github repo</a>, permalink accessed 2 October 2018.
  </footnote>
</tt></pre><p>
      Note that in the LaTeX parse, line alignment is respected perfectly:
      The first and last are ordinary LaTeX lines,
      the 2nd and 6th are commands bounding the code,
      and lines 3 through 5 are a code block.
    </p>
    <p>
      The C tokenization, on the other hand,
      shows no respect for lines.
      Most tokens are small parts of a line,
      and the two comments start in the middle of
      a line and end in the middle of one.
      For example, the first comment starts at column 17
      of line 1 and ends at column 5 of line 3.<footnote>
      See the <a href=
      "https://github.com/jeffreykegler/Marpa--R3/blob/08fa873687130fcfbe199a5f573375ad11322f3a/pub/varlex/idlit_ex2.t#L44"
      >test file</a>
      on Gihub.
      </footnote>
    </p>
    <h2>The method</h2>
    <p>The method I propose,
      and which I used in the example above,
      in a combination of Earley/Leo parsing
      and combinator parsing.
      Most of this (all except the variable-length tokens) is available
      in <a href=
      "https://metacpan.org/pod/distribution/Marpa-R2/pod/Marpa_R2.pod"
      >Marpa::R2</a>,
      which was Debian stable as of jessie.
    </p>
    <p>
      The final piece was the variable length tokens<footnote>
      There is <a href=
      "https://metacpan.org/pod/distribution/Marpa-R2/pod/Marpa_R2.pod"
      >documentation of the interface</a>,
      but for a reader who has just started to look at the Marpa::R3 project,
      it is not a good starting point.
      Once a user is familiar with Marpa::R3 standard DSL-based
      interface,
      they can start to learn about its alternatives <a href=
      "https://metacpan.org/pod/release/JKEGL/Marpa-R3-4.001_053/pod/External/Basic.pod"
      >here</a>.
      </footnote>,
      which I have just added to Marpa::R3,
      Marpa::R2's successor.
      Releases of <a href=
      "https://metacpan.org/pod/release/JKEGL/Marpa-R3-4.001_053/pod/Marpa_R3.pod"
      >Marpa::R3</a>
      pass a full test suite,
      and the documentation is kept up to date,
      but R3 is alpha, and the usual cautions<footnote>
        Specifically,
	since Marpa::R3 is alpha,
	its features are subject
        to change without notice, even between micro releases,
        and changes are made without concern for backward compatibility.
        This makes R3 unsuitable for a production application.
        Add to this that,
	while R3 is tested, it has seen much less
        usage and testing than R2, which has been very stable for
        some time.
      </footnote>
      apply.
    </p><h2>The example</h2>
    <p>The code that ran this example is <a href=
    "https://github.com/jeffreykegler/Marpa--R3/tree/08fa873687130fcfbe199a5f573375ad11322f3a/pub/varlex"
    >available on Github</a>.
      Most of the tools and techniques have been proven scalable,
      and I believe that all of them are,
      but the grammars used in our example are minimal.
      Only enough LaTex is implemented
      to recognize code blocks; and
      only enough C syntax is implemented to recognize comments.
    </p>
    <h2>The code, comments, etc.</h2>
    <p>To learn more about Marpa,
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
