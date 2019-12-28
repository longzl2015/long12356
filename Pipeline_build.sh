#!/usr/bin/env bash

echo "=== hexo install"
set -x;
npm install;

npm install hexo-deployer-git --save;
npm install hexo-filter-plantuml --save;
npm install hexo-generator-searchdb --save;

cat package.json

echo "=== hexo deploy"

node_modules/hexo/bin/hexo g -d;