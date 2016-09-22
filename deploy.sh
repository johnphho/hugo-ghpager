#!/bin/sh

git clone git@github.com:johnphho/johnphho.github.io.git public
hugo
cd public
git add --all .
git commit -m "[ci skip]"
git push origin master
