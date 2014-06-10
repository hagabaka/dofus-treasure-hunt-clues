#!/bin/sh

[ ! -f clues.json ] && phantomjs --disk-cache=true --load-images=false extract.coffee
