#!/bin/bash
#build/linux/x64/release/bundle/dupot_easy_flatpak sync
cp ~/.local/share/org.dupot.easyflatpak/flathub_database.db src/assets/db
rm ~/.local/share/org.dupot.easyflatpak/icons/Archive.zip
rm ~/.local/share/org.dupot.easyflatpak/icons/icons.zip

cp -r ~/.local/share/org.dupot.easyflatpak/icons/ /home/mika/code/github/python/dupotEasyFlatpak/src/assets
