#!/bin/sh

set -e
if [ ! -f clues.json ]; then
  ./build.sh
fi
cp clues.json clues.json.new
git checkout gh-pages
git checkout master -- index.html
cp clues.json.new clues.json
git add clues.json
git commit
git push origin gh-pages:gh-pages
git checkout master
mv clues.json.new clues.json
