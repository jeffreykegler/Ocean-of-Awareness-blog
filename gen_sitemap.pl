#!perl

use 5.010;
use strict;
use warnings;
use File::Find;

print <<'END_OF_TEXT';
<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.google.com/schemas/sitemap/0.84">
  <url>
    <loc>http://jeffreykegler.github.com/Ocean-of-Awareness-blog/</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>
END_OF_TEXT

sub wanted { my $name = $File::Find::name; $name =~ m/[.]html\z/xms and say $File::Find::name };
File::Find::find(\&wanted, './individual');

#   <url>
#     <loc>http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2012/r2_is_beta.html</loc>
#     <lastmod>2012-09-03</lastmod>
#   </url>
#   <url>
#     <loc>http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2012/dsl.html</loc>
#     <lastmod>2012-08-26</lastmod>
#   </url>
#   <url>
#     <loc>http://jeffreykegler.github.com/Ocean-of-Awareness-blog/individual/2012/announce.html</loc>
#     <lastmod>2012-08-26</lastmod>
#   </url>

print <<'END_OF_TEXT';
</urlset>
END_OF_TEXT