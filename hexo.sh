#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

set -x;

alias ccnpm="npm --registry=https://registry.npm.taobao.org"

ccnpm install --save ;

ccnpm install hexo-deployer-git --save;
ccnpm install hexo-filter-plantuml --save;

cat package.json

node_modules/hexo/bin/hexo g -d;