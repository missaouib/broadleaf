#!/bin/bash

# If a command fails then the deploy stops
set -e

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

#git submodule add -b master git@github.com:javachen/javachen.github.io.git public


rm -rf public

# Build the project.
hugo # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd public
# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -am "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..
