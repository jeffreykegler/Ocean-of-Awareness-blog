use 5.010;
use strict;
use warnings;

use Data::Dumper;
use Marpa::R2 2.082000;

my $input = <<'END_OF_STRING';
{
  name => 'test hash 1',
  42 => 'forty two',
 -42 => 'negative forty two',
 +42 => 'Perl 5 makes me disappear silently',
 key1 => 'normal Perl 5 key',
 key2 => 'another normal Perl 5 key',
 third key => 'Perl 5 syntax error',
}
{
 company name => 'Kamamaya Technology',
 employee 1 => first name => 'Jane',
 employee 1 => last name => 'Doe',
 employee 1 => title => 'President',
 employee 2 => first name => 'John',
 employee 2 => last name => 'Smith',
 employee 3 => first name => 'Clarence',
 employee 3 => last name => 'Darrow',
}
END_OF_STRING

my $source = <<'END_OF_SOURCE';
lexeme default = latm => 1 # handy boilerplate
:default ::= action => ::array

hashes ::= hash+
hash ::= ('{') <keyed values> ('}') action => My_Actions::make_hash_ref
<keyed values> ::= <keyed value>* separator => comma
<keyed value> ::= <key series> ('=>') value action => My_Actions::kv_flatten
<key series> ::= key+ separator => <wide comma> proper => 1
key ::= word1 <other words maybe> action => My_Actions::make_key
<other words maybe> ::= <other word>*
value ::= string action => ::first

:discard ~ <ws chars>
<ws chars> ~ [\s]+
comma ~ ','
<wide comma> ~ '=>'
<other word> ~ <word chars>
<string> ~ ['] <string chars maybe> [']
<string chars maybe> ~ [^']*
word1 ~ <good initial character> <word chars maybe>
# reserve some first characters for other uses
<good initial character> ~ [^$@%\s[{<('"] # reserve some 
<word chars> ~ [\w]+
<word chars maybe> ~ [\w]*
END_OF_SOURCE

my $g = Marpa::R2::Scanless::G->new( { source  => \$source } );
my $r = Marpa::R2::Scanless::R->new( { grammar => $g } );
$r->read( \$input );
my $value_ref = $r->value() or die "No parse";
say Data::Dumper::Dumper($value_ref);

package My_Actions;

sub make_key {
    my ( undef, $first_word, $other_words ) = @_;
    return join q{ }, $first_word, @{$other_words};
}

sub kv_flatten {
    my ( undef, $keys, $value ) = @_;
    return [ @{$keys}, $value ];
}

# Perl has ragged hashes of hashes, but the syntax is not
# friendly to them.  I considered putting together the
# assignment as a string, and doing a string eval, which
# certainly would have been simpler.  For better
# or worse, in the following code I work with hash references.
# Strings eval's are usually discouraged, but this may be
# one example where their use could have been justified.
sub make_hash_ref {
    my ( undef, $elements ) = @_;
    my $hash_ref = {};
    for my $element ( @{$elements} ) {
        my @keyed_value = @{$element};
        die "bad keyed value: ", Data::Dumper::Dumper($element)
            if scalar @keyed_value < 2;
        my $hash_at_depth = $hash_ref;
        my $last_key_ix   = $#keyed_value - 1;
        my $key;
        for ( my $key_ix = 0; $key_ix < $last_key_ix; $key_ix++ ) {
            $key = $keyed_value[$key_ix];
            $hash_at_depth->{$key} = {} if not exists $hash_at_depth->{$key};
            die "Attempt to use ", join q{->}, @keyed_value[ 0 .. $key_ix ],
                "as both scalar and hash\n",
                '  Element was ', Data::Dumper::Dumper($element)
                if ref $hash_at_depth ne 'HASH';
            $hash_at_depth = $hash_at_depth->{$key};
        } ## end for ( my $key_ix = 0; $key_ix < $last_key_ix; $key_ix...)
        $key = $keyed_value[$last_key_ix];
        $hash_at_depth->{$key} = pop @keyed_value;
    } ## end for my $element ( @{$elements} )
    return $hash_ref;
} ## end sub make_hash_ref
