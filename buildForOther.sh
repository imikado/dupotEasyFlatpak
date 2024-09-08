#!/bin/bash
rm -rf dist/2*
cp buildAsset/other/settings.json assets/
./buildDeb.sh
./buildRpm.sh
