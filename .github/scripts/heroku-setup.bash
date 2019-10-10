#!/bin/bash

set -eux

git config --global user.name ${GIT_NAME}
git config --global user.email ${GIT_EMAIL}
mkdir .deploy_heroku
cd .deploy_heroku
git init
echo "{ \"root\": \"public/\" }" > static.json
git add -A
git commit -m "First commit"
