
dummy:

all: sitemap.xml metapages/chronological.html
	perl work/blosxom.cgi

sitemap.xml:
	perl work/gen_sitemap.pl > sitemap.xml

metapages/chronological.html: plugins/state/dates
	perl work/gen_chronological.pl > metapages/chronological.html

ping:
	wget 'www.google.com/webmasters/tools/ping?sitemap=http://jeffreykegler.github.com/Ocean-of-Awareness-blog/sitemap.xml' -O google_ping.out
