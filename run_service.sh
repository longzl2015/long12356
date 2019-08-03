#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

npm install;

npm install hexo-deployer-git --save;
npm install hexo-filter-plantuml --save;
npm install hexo-generator-searchdb --save;

echo "清空旧数据"
hexo clean

echo "生成静态文件"
hexo g --debug

echo "启动服务"
hexo server


