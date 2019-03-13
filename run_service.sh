#!/bin/sh

basePath=`dirname $0`
cd ${basePath}

echo "清空旧数据"
hexo clean

echo "生成静态文件"
hexo g

echo "启动服务"
hexo server


