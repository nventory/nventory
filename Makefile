VER=0.5
TAGNAME=release-$(VER)

all: dist

test:

dist: test
	mkdir nventory-$(VER)
	(cd tags/$(TAGNAME) && find client docs server | cpio -pdum ../../nventory-$(VER))
	tar czf nventory-$(VER).tar.gz nventory-$(VER) \
		--exclude .svn
	rm -rf nventory-$(VER)
	md5sum nventory-$(VER).tar.gz > nventory-$(VER).tar.gz.md5
	gpg --detach --armor nventory-$(VER).tar.gz

tag:
	svn copy trunk tags/$(TAGNAME)

clean:
	rm nventory-*.tar.gz*

