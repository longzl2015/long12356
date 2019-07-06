#!/usr/bin/env bash

echo "=== auth ssh "

mkdir ~/.ssh/
mv kk ~/.ssh/id_rsa
echo "StrictHostKeyChecking no" > ~/.ssh/config
chmod 400 ~/.ssh/id_rsa
ssh -T git@github.com

echo "=== git config"

git config --global user.email "longzl@longzl.com"
git config --global user.name "longzl"

echo "=== hexo install"
set -x;
npm install;

npm install hexo-deployer-git --save;
npm install hexo-filter-plantuml --save;
npm install hexo-generator-searchdb --save;

cat package.json

echo "=== hexo deploy"

node_modules/hexo/bin/hexo g -d;