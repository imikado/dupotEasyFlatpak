#!/bin/bash
#build/linux/x64/release/bundle/dupot_easy_flatpak sync
cp ~/.data/flathub_database.db assets/db
rm ~/.data/Icons/Archive.zip
cd ~/.data/Icons/ ; zip Archive.zip *.png
mv ~/.data/Icons/Archive.zip /home/mika/code/github/flutter/dupotEasyFlatpak/assets/icons/