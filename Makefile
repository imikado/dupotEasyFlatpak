.PHONY: run clean install uninstall

PREFIX ?= /usr/local
DESTDIR ?=
APPID := org.dupot.easyflatpak
BINNAME := dupot_easy_flatpak
SHAREDIR := $(DESTDIR)$(PREFIX)/share
LIBDIR := $(SHAREDIR)/dupot-easy-flatpak
BINDIR := $(DESTDIR)$(PREFIX)/bin

run:
	python src/main.py

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +

install:
	install -d $(LIBDIR)
	cp -r src/. $(LIBDIR)/
	install -d $(BINDIR)
	printf '#!/bin/sh\nexec python3 "$(LIBDIR)/main.py" "$$@"\n' > $(BINDIR)/$(BINNAME)
	chmod 755 $(BINDIR)/$(BINNAME)
	install -Dm644 export/flatpak/$(APPID).desktop $(SHAREDIR)/applications/$(APPID).desktop
	install -Dm644 export/flatpak/$(APPID).appdata.xml $(SHAREDIR)/metainfo/$(APPID).appdata.xml
	install -Dm644 export/flatpak/$(APPID).xml $(SHAREDIR)/mime/packages/$(APPID).xml
	install -Dm644 export/flatpak/16x16.png $(SHAREDIR)/icons/hicolor/16x16/apps/$(APPID).png
	install -Dm644 export/flatpak/24x24.png $(SHAREDIR)/icons/hicolor/24x24/apps/$(APPID).png
	install -Dm644 export/flatpak/32x32.png $(SHAREDIR)/icons/hicolor/32x32/apps/$(APPID).png
	install -Dm644 export/flatpak/48x48.png $(SHAREDIR)/icons/hicolor/48x48/apps/$(APPID).png
	install -Dm644 export/flatpak/64x64.png $(SHAREDIR)/icons/hicolor/64x64/apps/$(APPID).png
	install -Dm644 export/flatpak/512x512.png $(SHAREDIR)/icons/hicolor/512x512/apps/$(APPID).png

uninstall:
	rm -rf $(LIBDIR)
	rm -f $(BINDIR)/$(BINNAME)
	rm -f $(SHAREDIR)/applications/$(APPID).desktop
	rm -f $(SHAREDIR)/metainfo/$(APPID).appdata.xml
	rm -f $(SHAREDIR)/mime/packages/$(APPID).xml
	rm -f $(SHAREDIR)/icons/hicolor/16x16/apps/$(APPID).png
	rm -f $(SHAREDIR)/icons/hicolor/24x24/apps/$(APPID).png
	rm -f $(SHAREDIR)/icons/hicolor/32x32/apps/$(APPID).png
	rm -f $(SHAREDIR)/icons/hicolor/48x48/apps/$(APPID).png
	rm -f $(SHAREDIR)/icons/hicolor/64x64/apps/$(APPID).png
	rm -f $(SHAREDIR)/icons/hicolor/512x512/apps/$(APPID).png
