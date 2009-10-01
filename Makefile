VER=0.81
TAGNAME=release-$(VER)

all: dist

test:

dist: test
	mkdir nventory-$(VER)
	(cd tags/$(TAGNAME) && find client docs server | cpio -pdum ../../nventory-$(VER))
	tar czf nventory-$(VER).tar.gz nventory-$(VER) \
		--exclude .svn
	rm -rf nventory-$(VER)
	openssl md5 nventory-$(VER).tar.gz > nventory-$(VER).tar.gz.md5
	openssl sha1 nventory-$(VER).tar.gz > nventory-$(VER).tar.gz.sha1
	gpg --detach --armor nventory-$(VER).tar.gz

tag:
	svn copy trunk tags/$(TAGNAME)

clean:
	rm nventory-*.tar.gz*

