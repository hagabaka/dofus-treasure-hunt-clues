#!/bin/sh

set -e
if [ ! -f site/clues.json ]; then
  ./build.sh
fi
cp site/clues.json clues.json.new
git checkout gh-pages

git checkout master -- site/
git mv -fk site/* .
cp clues.json.new clues.json
git commit -am 'Update files'
git push origin gh-pages:gh-pages

git checkout master
mv clues.json.new site/clues.json
