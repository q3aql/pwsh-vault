# dmenu - dynamic menu
# See LICENSE file for copyright and license details.

include config.mk

SRC = drw.c dmenu.c stest.c util.c
OBJ = $(SRC:.c=.o)

all: options dmenu stest

options:
	@echo dmenu build options:
	@echo "CFLAGS   = $(CFLAGS)"
	@echo "LDFLAGS  = $(LDFLAGS)"
	@echo "CC       = $(CC)"

.c.o:
	$(CC) -c $(CFLAGS) $<

config.h:
	cp config.def.h $@

$(OBJ): arg.h config.h config.mk drw.h

dmenu: dmenu.o drw.o util.o
	$(CC) -o $@ dmenu.o drw.o util.o $(LDFLAGS)

stest: stest.o
	$(CC) -o $@ stest.o $(LDFLAGS)

clean:
	rm -f dmenu stest $(OBJ) dmenu-$(VERSION).tar.gz

dist: clean
	mkdir -p dmenu-$(VERSION)
	cp LICENSE Makefile README arg.h config.def.h config.mk dmenu.1\
		drw.h util.h stest.1 $(SRC)\
		dmenu-$(VERSION)
	tar -cf dmenu-$(VERSION).tar dmenu-$(VERSION)
	gzip dmenu-$(VERSION).tar
	rm -rf dmenu-$(VERSION)

install: all
	mkdir -p $(DESTDIR)$(PREFIX)/
	mkdir -p /usr/share/fonts/truetype/ubuntumono/
	tar Jxvf fonts/ubuntumono-nerd-fonts.tar.xz -C /usr/share/fonts/truetype/ubuntumono/
	chmod 755 -R $(DESTDIR)$(PREFIX)/
	rm -rf $(DESTDIR)$(PREFIX)/*.o
	rm -rf $(DESTDIR)$(PREFIX)/*.orig
	cp -f dmenu $(DESTDIR)$(PREFIX)/pwsh-vaultm
	cp -f stest $(DESTDIR)$(PREFIX)/stest
	cp -f pwsh-vault.sh $(DESTDIR)$(PREFIX)/pwsh-vault
	cp -f pwsh-vault-cli.sh $(DESTDIR)$(PREFIX)/pwsh-vault-cli
	cp -f pwsh-vault-dl.sh $(DESTDIR)$(PREFIX)/pwsh-vault-dl
	cp -rf fonts $(DESTDIR)$(PREFIX)/
	cp -rf icon $(DESTDIR)$(PREFIX)/
	cp -rf icon/pwsh-vault.desktop /usr/share/applications/
	cp -rf icon/pwsh-vault-dl.desktop /usr/share/applications/
	chmod 755 $(DESTDIR)$(PREFIX)/pwsh-vaultm
	chmod 755 $(DESTDIR)$(PREFIX)/pwsh-vault
	chmod 755 $(DESTDIR)$(PREFIX)/pwsh-vault-cli
	chmod 755 $(DESTDIR)$(PREFIX)/pwsh-vault-dl
	chmod 755 $(DESTDIR)$(PREFIX)/stest
	rm -f /usr/bin/pwsh-vaultm
	rm -f /usr/bin/pwsh-vault
	rm -f /usr/bin/pwsh-vault-cli
	rm -f /usr/bin/pwsh-vault-dl
	ln -s $(DESTDIR)$(PREFIX)/pwsh-vault /usr/bin/pwsh-vault
	ln -s $(DESTDIR)$(PREFIX)/pwsh-vault-cli /usr/bin/pwsh-vault-cli
	ln -s $(DESTDIR)$(PREFIX)/pwsh-vault-dl /usr/bin/pwsh-vault-dl
	ln -s $(DESTDIR)$(PREFIX)/pwsh-vaultm /usr/bin/pwsh-vaultm

cygwin:
	cp -f pwsh-vault-cli.sh /usr/bin/pwsh-vault-cli
	cp -f pwsh-vault-dl.sh /usr/bin/pwsh-vault
	cp -f pwsh-vault-dl.sh /usr/bin/pwsh-vault-dl
	chmod 755 /usr/bin/pwsh-vault-cli
	chmod 755 /usr/bin/pwsh-vault-dl
	chmod 755 /usr/bin/pwsh-vault
	
termux:
	cp -f pwsh-vault-cli.sh /data/data/com.termux/files/usr/bin/pwsh-vault-cli
	cp -f pwsh-vault-dl.sh /data/data/com.termux/files/usr/bin/pwsh-vault-dl
	cp -f pwsh-vault-dl.sh /data/data/com.termux/files/usr/bin/pwsh-vault
	chmod 755 /data/data/com.termux/files/usr/bin/pwsh-vault-cli
	chmod 755 /data/data/com.termux/files/usr/bin/pwsh-vault-dl
	chmod 755 /data/data/com.termux/files/usr/bin/pwsh-vault

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/pwsh-vaultm\
		$(DESTDIR)$(PREFIX)/pwsh-vault\
		$(DESTDIR)$(PREFIX)/pwsh-vault-cli\
		$(DESTDIR)$(PREFIX)/pwsh-vault-dl\
		$(DESTDIR)$(PREFIX)/stest\
	rm -rf $(DESTDIR)$(PREFIX)
	rm -f /usr/bin/pwsh-vaultm
	rm -f /usr/bin/pwsh-vault-cli
	rm -f /usr/bin/pwsh-vault-dl
	rm -f /usr/bin/pwsh-vault
	rm -f /usr/share/applications/pwsh-vault.desktop
	rm -f /usr/share/applications/pwsh-vault-dl.desktop

.PHONY: all options clean dist install uninstall
