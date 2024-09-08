#!/bin/bash
cp buildAsset/flatpak/settings.json assets/
./build.sh
rm -rf dist/bundle
cp -r build/linux/x64/release/bundle dist/
cd dist
tar -czf bundle.tar.gz bundle
