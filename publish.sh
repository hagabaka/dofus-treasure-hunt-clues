#!/bin/sh

set -e
./build.sh
mv clues.json clues.json.new
git checkout gh-pages
git checkout master -- index.html
mv clues.json.new clues.json
git add clues.json
git commit
git push origin gh-pages:gh-pages
git checkout master
