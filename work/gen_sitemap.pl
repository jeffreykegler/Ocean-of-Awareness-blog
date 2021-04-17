#!perl

use 5.010;
use strict;
use warnings;
use File::Find;

print <<'END_OF_TEXT';
<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.google.com/schemas/sitemap/0.9">
  <url>
    <loc>http://jeffreykegler.github.io/Ocean-of-Awareness-blog/</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>http://jeffreykegler.github.io/Ocean-of-Awareness-blog/metapages/chronological.html</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>http://jeffreykegler.github.io/Ocean-of-Awareness-blog/metapages/annotated.html</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
END_OF_TEXT

my $root = 'http://jeffreykegler.github.io/Ocean-of-Awareness-blog/';
our @filelist = ();
sub wanted { my $name = $File::Find::name; $name =~ m/[.]html\z/xms and push @filelist, $File::Find::name };
File::Find::find(\&wanted, 'individual');

for my $file (@filelist) {
   say '  <url>';
   say '    <loc>', ($root . $file), '</loc>';
   (my $time_file = $file) =~ s/ [.] html \z /txt/xms;
   $time_file = $file if not -r $time_file;
   my $git_stamp = qx{git log "--pretty=format:%ci" -n 1 $time_file};
   $git_stamp =~ s/[ ]/T/xms;
   $git_stamp =~ s/[ ]//gxms;
   $git_stamp =~ s{  (\d\d) (\d\d) \z }{$1:$2}xms;
   say '    <lastmod>', $git_stamp, '</lastmod>';
   say '  </url>';
}

print <<'END_OF_TEXT';
</urlset>
END_OF_TEXT
