#!/bin/sh
mkdir -p deploy
cp -r akihabara seedrandom-min.js index.html style.css *.png deploy/.

git checkout gh-pages
mv deploy/* .
mv deploy/akihabara/* akihabara/.
git add akihabara seedrandom-min.js index.html style.css *.png

rm -rf deploy
git commit -am 'auto-deploy'
git push origin gh-pages

git checkout master
