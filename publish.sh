#!/bin/sh

set -e
git checkout gh-pages

git checkout master -- site/
git mv -fk site/* .
git commit -am 'Update files'
git push origin gh-pages:gh-pages

git checkout master
