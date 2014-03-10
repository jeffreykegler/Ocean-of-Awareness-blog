use 5.010;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Marpa::R2 2.082000;

my $input = <<'END_OF_STRING';
{
  42 => 'forty two',
 -42 => 'negative forty two',
 +42 => 'Perl 5 makes me disappear silently',
 key1 => 'normal Perl 5 key',
 key2 => 'another normal Perl 5 key',
 I am a very long key => 'Perl 5 syntax error',
 first key => 'Perl 5 syntax error',
 second key => 'Perl 5 syntax error',
}
END_OF_STRING

my $source = <<'END_OF_SOURCE';
lexeme default = latm => 1 # handy boilerplate
:default ::= action => ::array

hashes ::= hash+
hash ::= ('{') <key value pairs> ('}')
<key value pairs> ::= <key value pair>* separator => comma
<key value pair> ::= key ('=>') value
key ::= word1 <other words maybe> action => My_Actions::make_key
<other words maybe> ::= <other word>*
value ::= string action => ::first

:discard ~ <ws chars>
<ws chars> ~ [\s]+
comma ~ ','
<other word> ~ <word chars>
<string> ~ ['] <string chars maybe> [']
<string chars maybe> ~ [^']*
word1 ~ <good initial character> <word chars maybe>
<good initial character> ~ [^$@%\s]
<word chars> ~ [\w]+
<word chars maybe> ~ [\w]*
END_OF_SOURCE

my $g = Marpa::R2::Scanless::G->new({ source => \$source});
my $r = Marpa::R2::Scanless::R->new({ grammar => $g });
$r->read(\$input);
my $value_ref = $r->value() or die "No parse";
say Dumper($value_ref);

package My_Actions;

sub make_key {
   my (undef, $first_word, $other_words) = @_;
   return join q{ }, $first_word, @{$other_words};
}
