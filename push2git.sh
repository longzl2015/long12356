#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

echo "清空旧数据"
hexo clean

echo "生成静态文件"
hexo g

echo "发布到github"
hexo deploy



basePath=`dirname $0`
cd ${basePath}

git commit -a -m 'update' & git push origin master


