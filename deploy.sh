#!/bin/bash

echo `date`

msg="$*"


rm -rf .jekyll-metadata

qrsync qiniu-images.json


cd _posts

#sed -i "" 's/javachen\-rs\.qiniudn\.com/7xnrdo\.com1\.z0\.glb.clouddn\.com/g' */*

cd ..

rm -rf _site/*
jekyll build

git pull

git add .
git status
git commit -m  ”$msg“
git push origin master

cd ../javachen.github.io
git pull
rm -rf  page* 20* assets
cp -r ../javachen-blog-theme/_site/* .
rm -rf  deploy.sh qiniu-images.json

# echo "post sitemap.xml to baidu"
# curl -H 'Content-Type:text/xml' --data-binary @sitemap.xml "http://data.zz.baidu.com/update?site=blog.javachen.com&token=2CeQfTIrbOgmAqpv"

git add .
git commit -m "$msg"
git push origin master

echo `date`
exit 0
