#!/bin/sh

set -e
if [ ! -f clues.json ]; then
  ./build.sh
fi
cp clues.json clues.json.new
git checkout gh-pages

git checkout pretty -- index.html
git checkout pretty -- opensearch.xml
git checkout pretty -- jquery.event.scroll.js
git checkout pretty -- blur-blocked.js
git checkout pretty -- clip-path-polygon.js
mkdir -p pretty
mv index.html opensearch.xml jquery.event.scroll.js blur-blocked.js clip-path-polygon.js pretty
cp clues.json.new pretty/clues.json

git checkout master -- index.html
git checkout master -- opensearch.xml
cp clues.json.new clues.json
git commit -am 'Update files'
git push origin gh-pages:gh-pages

git checkout master
mv clues.json.new clues.json
