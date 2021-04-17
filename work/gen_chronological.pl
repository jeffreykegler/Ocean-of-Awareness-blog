#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use autodie;

my %post_by_date;
open my $dates_fh, q{<}, 'plugins/state/dates';
while (my $line = <$dates_fh>) {
    chomp $line;
    my ($julian, $file) = split /\s+/xms, $line, 2;
    $post_by_date{$julian} = $file;
}
close $dates_fh;

our $blog_title = 'Ocean of Awareness';
our $url = 'http://jeffreykegler.github.io/Ocean-of-Awareness-blog/';

sub interpolate {

    package blosxom;
    my $template = shift;
    $template =~ s/(\$\w+(?:::)?\w*)/"defined $1 ? $1 : ''"/gee;
    return $template;
} ## end sub interpolate

open my $head_fh, q{<}, 'source/head.html';
my $header = join q{}, <$head_fh>;
close $head_fh;
print interpolate($header);

say '<h1>Posts, in reverse chronological order</h1>';
my $previous_year;
for my $julian (sort { $b <=> $a } keys %post_by_date) {
    my $file = $post_by_date{$julian};
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($julian);
    $year += 1900;
    open my $post_fh, q{<}, $file;
    my $title = <$post_fh>;
    if (not defined $previous_year or $previous_year != $year) {
        say "<h2>$year</h2>";
	$previous_year = $year;
    }
    my @month_names = qw( January February March April May June
	July August September October November December );
	my $month_name = $month_names[$mon];
    my $href_file = $file;
    $href_file =~ s{^source\/}{};
    $href_file =~ s/[.]txt$//;
    $href_file .= '.html';
    say qq{<p>$month_name $mday <a href="$url$href_file">$title</a></p>};
}
  
open my $foot_fh, q{<}, 'source/foot.html';
print join q{}, <$foot_fh>;
close $foot_fh;

