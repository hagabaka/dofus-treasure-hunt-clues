#!/bin/sh

[ ! -f clues.json ] && phantomjs --disk-cache=true --load-images=false extract.coffee
mv clues.json clues.json.new
git checkout gh-pages
git checkout master -- index.html
mv clues.json.new clues.json
git add clues.json

