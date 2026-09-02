.PHONY: run clean stage install uninstall

PREFIX ?= /usr/local
DESTDIR ?=
APPID := org.dupot.easyflatpak
BINNAME := dupot_easy_flatpak
SHAREDIR := $(DESTDIR)$(PREFIX)/share
LIBDIR := $(SHAREDIR)/dupot-easy-flatpak
BINDIR := $(DESTDIR)$(PREFIX)/bin
STAGEDIR := $(CURDIR)/.makestage
PYTHON ?= python3

run:
	python src/main.py

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	rm -rf $(STAGEDIR)

# Stage a patched copy of src/ + export/ so `install` never mutates the
# tracked repo files.
stage:
	rm -rf $(STAGEDIR)
	mkdir -p $(STAGEDIR)
	cp -r src $(STAGEDIR)/src
	cp -r export $(STAGEDIR)/export
	# `cp` (used by system_api.py to populate the user data dir) preserves
	# the source mode. Files copied from the Nix store are 0444, so a FRESH
	# install ends up with a read-only data dir and sqlite refuses to write
	# on the very first query.
	sed -i \
	  -e "s/subprocess.run(\['cp', path_from, path_to\])/subprocess.run(['cp', '--no-preserve=mode', path_from, path_to])/" \
	  -e "s/subprocess.run(\['cp', '-r',path_from, path_to\])/subprocess.run(['cp', '-r', '--no-preserve=mode', path_from, path_to])/" \
	  $(STAGEDIR)/src/infrastructure/api/system_api.py
	# Also repair installations already left read-only: `cp` keeps an
	# existing destination's mode, so a 0444 data dir wouldn't be fixed by
	# the change above. This chmod must run before the FIRST write, which is
	# reset_updated_for_all(), not UpdateDatabaseFromApiUc.
	sed -i '/^            if should_reset_lastupdate:/i\
                for root, dirs, files in os.walk(data_path):\
                    for directory in dirs:\
                        os.chmod(os.path.join(root, directory), 0o700)\
                    for file_name in files:\
                        os.chmod(os.path.join(root, file_name), 0o600)' \
	  $(STAGEDIR)/src/main.py
	$(PYTHON) -m py_compile $(STAGEDIR)/src/main.py
	# Match Gtk.Application's application_id so desktop shells associate the
	# running Wayland window with the launcher.
	sed -i 's/StartupWMClass=dupot_easy_flatpak/StartupWMClass=$(APPID)/' \
	  $(STAGEDIR)/export/flatpak/$(APPID).desktop

install: stage
	install -d $(LIBDIR)
	cp -r $(STAGEDIR)/src/. $(LIBDIR)/
	install -d $(BINDIR)
	printf '#!/bin/sh\nexec python3 "$(LIBDIR)/main.py" "$$@"\n' > $(BINDIR)/$(BINNAME)
	chmod 755 $(BINDIR)/$(BINNAME)
	install -Dm644 $(STAGEDIR)/export/flatpak/$(APPID).desktop $(SHAREDIR)/applications/$(APPID).desktop
	install -Dm644 $(STAGEDIR)/export/flatpak/$(APPID).appdata.xml $(SHAREDIR)/metainfo/$(APPID).appdata.xml
	install -Dm644 $(STAGEDIR)/export/flatpak/$(APPID).xml $(SHAREDIR)/mime/packages/$(APPID).xml
	install -Dm644 $(STAGEDIR)/export/flatpak/16x16.png $(SHAREDIR)/icons/hicolor/16x16/apps/$(APPID).png
	install -Dm644 $(STAGEDIR)/export/flatpak/24x24.png $(SHAREDIR)/icons/hicolor/24x24/apps/$(APPID).png
	install -Dm644 $(STAGEDIR)/export/flatpak/32x32.png $(SHAREDIR)/icons/hicolor/32x32/apps/$(APPID).png
	install -Dm644 $(STAGEDIR)/export/flatpak/48x48.png $(SHAREDIR)/icons/hicolor/48x48/apps/$(APPID).png
	install -Dm644 $(STAGEDIR)/export/flatpak/64x64.png $(SHAREDIR)/icons/hicolor/64x64/apps/$(APPID).png
	install -Dm644 $(STAGEDIR)/export/flatpak/512x512.png $(SHAREDIR)/icons/hicolor/512x512/apps/$(APPID).png
	rm -rf $(STAGEDIR)

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
