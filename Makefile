# Edited for Debian GNU/Linux
DESTDIR =

NAME    = nodes
VERSION = 0.1
PROGS   = 
SPROGS  = bin/nodex bin/netty bin/netty-ctl bin/netty-login
BIN     = $(DESTDIR)/usr/bin
ETC	= $(DESTDIR)/etc
LOG	= $(DESTDIR)/var/log/nodes
SBIN    = $(DESTDIR)/usr/sbin
SHARE   = $(DESTDIR)/usr/share/${NAME}
TARBALL = $(NAME)_$(VERSION).orig.tar.gz

build: node_modules libs
	cd src ; make
	echo "var _build_date='`date`';" > static/app/shell/version.js

run:
	bin/netty

install: build
	@echo "Installing in ${DESTDIR}"
#	install -d $(BIN)
#	install $(PROGS) $(BIN)
	install -d $(ETC)/$(NAME)
	install etc/*.* $(ETC)/$(NAME)
	install -d $(SBIN)
	install $(SPROGS) $(SBIN)
	install -d $(SHARE)
#	install netty.js nodex.js $(SHARE)
	cp -a static $(SHARE)
	cp -a node_modules $(SHARE)
	cp -a doc $(SHARE)
	install -d $(LOG)

# meta stuff

newpackage:
	dch -R 'New package release'
	make package

package: tarball
	@find . -name '*~' | xargs rm -f 
	debuild -us -uc -i

clean:
	rm -f make.log

node_modules:
	npm install

libs:
	cp lib/*.js node_modules

realclean: clean
	-debuild clean
	-rm -rf node_modules


tarball: clean
	cd .. ; tar czvf $(TARBALL) --exclude=.git $(NAME) >> /dev/null

view:
	(sleep 1; gnome-open http://localhost:3000) &

