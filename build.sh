#!/bin/sh

if [ ! -f jquery.ba-replacetext.js ]; then
  wget http://github.com/cowboy/jquery-replacetext/raw/master/jquery.ba-replacetext.js
fi

if [ ! -f underscore.js ]; then
  wget http://underscorejs.org/underscore.js
fi

if [ ! -f clues.json ]; then
  phantomjs --disk-cache=true --load-images=false extract.coffee
fi
