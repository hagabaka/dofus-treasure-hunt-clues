#!/bin/sh

set -e
if [ ! -f clues.json ]; then
  ./build.sh
fi
cp clues.json clues.json.new
git checkout gh-pages
git checkout master -- index.html
git checkout master -- opensearch.xml
cp clues.json.new clues.json
git add clues.json
git commit -m 'Update files'
git push origin gh-pages:gh-pages
git checkout master
mv clues.json.new clues.json