#!/bin/sh

if [ ! -f clues.json ]; then
  phantomjs --disk-cache=true --load-images=false extract.coffee
fi
