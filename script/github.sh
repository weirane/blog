#!/bin/sh
set -e

cd _site
git config user.name "GitHub Actions"
git config user.email "noreply@github.com"
git add --all
git commit --message "Auto deploy from GitHub Actions build $GITHUB_RUN_NUMBER" \
           --message "$(git -C .. log -1 --pretty="[%h] %s")"
git remote add deploy "https://$GH_TOKEN@github.com/weirane/weirane.github.io.git" >/dev/null 2>&1
git push deploy master
