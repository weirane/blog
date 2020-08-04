#!/bin/sh
set -e

cd _site
cat >README.md <<EOF
Automatically built by Travis CI.
[![Build Status](https://travis-ci.org/weirane/blog.svg)](https://travis-ci.org/weirane/blog)

The source is [here](https://github.com/weirane/blog).
EOF
git init
git config user.name "Travis CI"
git config user.email "travis@travis-ci.org"
git add --all
git commit --message "Auto deploy from Travis CI build $TRAVIS_BUILD_NUMBER" --message "$(git -C .. log -1 --pretty="[%h] %b")"
git remote add deploy "https://$GH_TOKEN@github.com/weirane/weirane.github.io.git" >/dev/null 2>&1
git push --force deploy master
