#!perl

use 5.010;
use strict;
use warnings;

use XML::Feed;

my $feed = XML::Feed->parse(URI->new('http://blogs.perl.org/users/jeffrey_kegler/atom.xml'))
    or die XML::Feed->errstr;
print $feed->title, "\n";
for my $entry ($feed->entries) {
        print
	"=== Title: ", $entry->title, "\n",
	"=== ID: ", $entry->id(), "\n",
	"=== Content:\n", $entry->content()->body(),
	"\n\n";
}

