
dummy:
	@echo The main target is '"all"'

all:
	(cd metasources; make all)
	perl work/blosxom.cgi

full: all
	perl work/gen_sitemap.pl > sitemap.xml
	perl work/gen_chronological.pl > metapages/chronological.html

ping:
	wget 'www.google.com/webmasters/tools/ping?sitemap=http://jeffreykegler.github.com/Ocean-of-Awareness-blog/sitemap.xml' -O google_ping.out
	cat google_ping.out
