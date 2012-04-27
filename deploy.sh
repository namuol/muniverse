#!/bin/sh
mkdir -p deploy
pushd build
cp -r akihabara *.js *.html *.css *.png ../deploy/.

popd
git checkout gh-pages
mv deploy/* .
mv deploy/akihabara/* akihabara/.
git add akihabara *.js *.html *.css *.png

rm -rf deploy
git commit -am 'auto-deploy'
git push origin gh-pages

git checkout master
