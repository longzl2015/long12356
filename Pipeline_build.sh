#!/usr/bin/env bash

echo "=== hexo install"
set -x;
cnpm install;
cnpm install hexo-filter-plantuml --save;
cnpm install hexo-generator-searchdb --save;

echo "=== 生成静态文件"
node_modules/hexo/bin/hexo g;
ls -l

echo "=== 部署到 git"
node_modules/hexo/bin/hexo d;