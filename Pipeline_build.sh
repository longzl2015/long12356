#!/usr/bin/env bash

echo "=== hexo install"
set -x;
npm install;
npm install hexo-filter-plantuml --save;
npm install hexo-generator-searchdb --save;
node_modules/hexo/bin/hexo g;

echo "=== "
rm -rf scaffolds
rm -rf source
rm -rf themes
rm -rf .gitignore
rm -rf _config.yml
rm -rf CodePipeline.sh
rm -rf package.json
rm -rf Pipeline_build.sh
rm -rf push2git.sh
rm -rf README.md
rm -rf run_service.sh
mv public/* ./
rm -rf public