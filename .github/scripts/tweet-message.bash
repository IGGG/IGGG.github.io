#!/bin/bash

set -eux

BASE_URL="https://iggg.github.io"
TWEET_MESSAGE=""
LATEST=0

DIFF_FILES=`git diff HEAD^...HEAD --name-only --diff-filter=A -- source/_posts/*.md`
for FILE_PATH in $DIFF_FILES ; do
  TITLE=`head ${FILE_PATH} | grep '^title:' | sed 's/^title: *//g'`
  DATE=`head ${FILE_PATH} | grep '^date:' | sed -e 's/^date: *\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\) .*$/\1\/\2\/\3/g'`
  FILE_NAME=`echo ${FILE_PATH} | sed -e 's/source\/_posts\/\(.*\)\.md/\1/'`
  MESSAGE="${TITLE} ${BASE_URL}/${DATE}/${FILE_NAME}"

  DATE_TIME=`date -d "${DATE}" '+%s'`
  if [ $DATE_TIME -gt $LATEST ] ; then
    TWEET_MESSAGE="【ブログを更新しました】${MESSAGE}"
    LATEST=${DATE_TIME}
  fi
done

echo ${TWEET_MESSAGE}
