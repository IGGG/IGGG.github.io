#!/bin/bash

set -eux

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"
mkdir -p ${HOME}/.ssh
ssh-keyscan -t rsa github.com > ${HOME}/.ssh/known_hosts
echo "${DEPLOY_KEY}" > ${HOME}/.ssh/id_rsa
chmod 400 ${HOME}/.ssh/id_rsa

# deploy by hexo
./node_modules/.bin/hexo deploy --config $1
