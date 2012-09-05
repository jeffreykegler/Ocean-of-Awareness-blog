
dummy:

all: sitemap.xml

sitemap.xml:
	perl gen_sitemap.pl > sitemap.xml
