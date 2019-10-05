#!/bin/bash

set -eux

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"
mkdir -p /root/.ssh
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
echo "${DEPLOY_KEY}" > /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa

# deploy by hexo
./node_modules/.bin/hexo deploy --config $1