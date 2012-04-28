#!/bin/sh
mkdir -p deploy
pushd build
cp -r akihabara swf *.js *.html *.css *.png *.wav ../deploy/.

popd
git checkout gh-pages
mv deploy/* .
mv deploy/akihabara/* akihabara/.
git add akihabara swf *.js *.html *.css *.png *.wav

rm -rf deploy
git commit -am 'auto-deploy'
git push origin gh-pages

git checkout master
