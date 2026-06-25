#!/bin/sh
version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
dart compile exe bin/auto_commit.dart -o build/flit -DAPP_VERSION="$version"
