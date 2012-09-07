#!perl

use 5.010;
use strict;
use warnings;
use autodie;

use HTML::TokeParser;
use Text::Wrap qw(wrap);
use Text::Diff;

my $perl_org_file_name = shift;
die if not defined $perl_org_file_name;
(my $txt_file_name = $perl_org_file_name) =~ s{work/pages/}{source/individual/};
$txt_file_name =~ s/[.]html/.txt/;

open my $fh, q{<}, $perl_org_file_name;
my $perl_org_file = join q{}, <$fh>;
close $fh;
$perl_org_file =~ s/\A .* [<] div \s+ class[=]["]entry-body["][>] \s* //xms;
$perl_org_file =~ s{\s+ [<] [/] div[>][<][!]-- \s+ [.]entry-body \s+ --[>].*\z}{}xms;

open $fh, q{<}, $txt_file_name;
<$fh>; # throw away first line
my $txt_file = join q{}, <$fh>;
close $fh;

sub file_to_text {
    my ($file) = @_;
    my $p      = HTML::TokeParser->new($file);
    my $text   = '';
    while ( my $token = $p->get_token() ) {
        next unless $token->[0] eq 'T';
        $text .= $token->[1];
    }
    $text =~ s/\s+/ /g;
    $text =~ s/^\s*//g;
    $text =~ s/\s*$//g;
    return \Text::Wrap::wrap('', '', $text);
} ## end sub file_to_text

my $diffs = Text::Diff::diff file_to_text(\$perl_org_file), file_to_text(\$txt_file);
if ($diffs) {
  say "$perl_org_file_name -> $txt_file_name:";
  say $diffs;
}
