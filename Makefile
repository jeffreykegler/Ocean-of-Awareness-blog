
dummy:

all: sitemap.xml
	perl work/blosxom.cgi

sitemap.xml:
	perl work/gen_sitemap.pl > sitemap.xml
	perl work/gen_chronological.pl > individual/source/chronological.txt
