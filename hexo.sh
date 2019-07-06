#!/bin/sh

set -x;

npm install hexo --save;

npm install hexo-deployer-git --save;
npm install hexo-filter-plantuml --save;

npm install hexo-generator-archive --save;
npm install hexo-generator-category --save;
npm install hexo-generator-index --save;
npm install hexo-generator-tag --save;

npm install hexo-renderer-ejs --save;
npm install hexo-renderer-marked --save;
npm install hexo-renderer-stylus --save;

cat package.json
npm list;
node_modules/hexo/bin/hexo g -d;