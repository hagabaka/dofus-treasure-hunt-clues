#!/bin/sh

set -e
if [ ! -f jquery.ba-replacetext.js ]; then
  wget http://github.com/cowboy/jquery-replacetext/raw/master/jquery.ba-replacetext.js
fi

if [ ! -f underscore.js ]; then
  wget http://underscorejs.org/underscore.js
fi

if [ ! -f sugar-date.js ]; then
  curl -o sugar-date.js -d core_package=core -d date_package=date sugarjs.com/download
fi

phantomjs --disk-cache=true --load-images=false extract.coffee
mv clues.json site/
git show gh-pages:clues.json | git diff --no-index -- - site/clues.json || true
