#!/bin/bash
grep "version:" pubspec.yaml | grep -v "version:" > assets/version.txt

flutter build linux --release