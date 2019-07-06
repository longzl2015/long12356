#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

set -x;

alias ccnpm="npm --registry=https://registry.npm.taobao.org"

echo ""


ccnpm install --save ;

ccnpm install hexo-deployer-git --save;
ccnpm install hexo-filter-plantuml --save;
ccnpm install hexo-generator-searchdb --save;

cat package.json

node_modules/hexo/bin/hexo g -d;