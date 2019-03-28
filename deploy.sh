#!/bin/bash

echo `date`

msg="update:$*"


rm -rf .jekyll-metadata

qrsync qiniu-images.json


cd _posts

#sed -i "" 's/javachen\-rs\.qiniudn\.com/7xnrdo\.com1\.z0\.glb.clouddn\.com/g' */*

cd ..

rm -rf _site/*
jekyll build

git add .
git status
git commit -m "update at `date` $msg"
git push origin master

echo "post sitemap.txt to baidu"
curl -H 'Content-Type:text/plain' --data-binary @_site/sitemap.txt "http://data.zz.baidu.com/update?site=blog.javachen.com&token=2CeQfTIrbOgmAqpv"

cd ../javachen.github.io
git pull
rm -rf  ./*
cp -r ../javachen-blog/_site/* .
rm -rf  deploy.sh qiniu-images.json

git add .
git commit -m "$msg"
git push origin master

echo `date`
exit 0
