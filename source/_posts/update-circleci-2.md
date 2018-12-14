---
title: CircleCI の設定ファイルを 2.0 に更新
tags:
  - CircleCI
  - Heroku
  - GitHub
categories: Web
date: 2018-12-15 02:00:00
cover: "/images/update-circleci-2/iggg-github-io.jpg"
---

IGGG ソフトウェア基盤部のひげです。
1年ぶりの更新です。

本記事は[IGGG アドベントカレンダー 2018](http://www.adventar.org/calendars/3217) 15日目の記事です。
まぁ今回はほとんど埋まっていませんが(笑)

本当は別の話を書こうと思っていたんだけど、記事を書くためにこのサイトを整備、というかほったらかしにいていた CircleCI 2.0 へのアップデートをしたら思いの外大変だったのでその過程を書きたいと思います。
まぁみんな既に 2.0 への更新は済んでそうですけどね。

## ここの構成

このサイトは CircleCI を使って自動デプロイなどを導入している:

- [GitHub Pages + Hexo + CircleCI + Heroku で自動デプロイ管理｜群馬大学電子計算機研究会 IGGG](https://iggg.github.io/2016/05/30/use-circle-ci/)

![](/images/update-circleci-2/iggg-github-io.jpg)

実はこれ、 CircleCI 1.0 のままだった。
もう2年半近く前だからしょうがないね。
元々の設定はこんな感じ:

```yaml
machine:
  timezone: Asia/Tokyo
  node:
    version: 4.4.5
deployment:
  production:
    branch: source
    commands:
      - git config --global user.name "IGGGorg"
      - git config --global user.email "contact@iggg.org"
      - git submodule init
      - git submodule update
      - ./node_modules/.bin/hexo clean
      - ./node_modules/.bin/hexo generate
      - ./node_modules/.bin/hexo deploy
  staging:
    branch: staging
    commands:
      - git config --global user.name "IGGGorg"
      - git config --global user.email "contcat@iggg.org"
      - ./node_modules/.bin/hexo clean
      - ./node_modules/.bin/hexo generate
      - ./node_modules/.bin/hexo deploy --branch $CIRCLE_BRANCH --config _staging_config.yml
general:
  branches:
    ignore:
      - master
```

## 更新作業

ちなみに最終的にこんな感じ:

```yaml
defaults: &defaults
  docker:
    - image: circleci/node:11.4.0
      environment:
        TZ: Asia/Tokyo
  working_directory: ~/work

version: 2
jobs:
  build:
    <<: *defaults
    steps:
      - checkout
      - restore_cache:
          keys:
          - v1-dependencies-{{ checksum "package.json" }}
          # fallback to using the latest cache if no exact match is found
          - v1-dependencies-
      - run: npm install
      - run: node_modules/.bin/hexo clean
      - run: node_modules/.bin/hexo generate
      - save_cache:
          paths:
            - node_modules
          key: v1-dependencies-{{ checksum "package.json" }}
      - persist_to_workspace:
          root: .
          paths: [ '*' ]
  deploy-production:
    <<: *defaults
    steps:
      - attach_workspace:
          at: .
      - run:
          name: init
          command: |
            git config --global user.name "IGGGorg"
            git config --global user.email "contact@iggg.org"
            mkdir ~/.ssh/ && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" > ~/.ssh/config
            git submodule init
            git submodule update
      - run:
          name: deploy to production
          command: ./node_modules/.bin/hexo deploy
  deploy-staging:
    <<: *defaults
    steps:
      - attach_workspace:
          at: .
      - run:
          name: init
          command: |
            git config --global user.name "IGGGorg"
            git config --global user.email "contact@iggg.org"
      - run:
          name: deploy to staging
          command: |
            mkdir .deploy
            cd .deploy
            git init
            echo "{ \"root\": \"public/\" }" > static.json
            git add -A
            git commit -m "First commit"
            cp -r ../public .
            git add -A
            git commit -m "Site updated"
            git push -u https://heroku:$HEROKU_API_KEY@git.heroku.com/iggg-github-io-staging.git master -f

workflows:
  version: 2
  build-and-deploy:
    jobs:
      - build:
          filters:
            branches:
              ignore:
                - master
      - deploy-production:
          requires:
            - build
          filters:
            branches:
              only:
                - source
      - deploy-staging:
          requires:
            - build
          filters:
            branches:
              only:
                - staging
```

やっつけでやったからだいぶ余計な部分がありそう。

### CircleCI 2.0

旧バージョンである [CircleCI 1.0 は2018年8月31日に終了](https://circleci.com/blog/sunsetting-1-0/)し、以降は 2.0 でしか CI を回せなくなった（このサイトは2017年3月以降回していない笑）。

変更の仕方はそこまで難しくない。
下記の公式ドキュメントにしたがって変更して行けば良い:

- [Migrating a Linux Project from 1.0 to 2.0 - CircleCI](https://circleci.com/docs/2.0/migrating-from-1-2/)

手順をざっくりと抜粋すると:

1. `/circle.yml` を `/.circleci/config.yml` に置換
2. `version: 2` を冒頭に追加
3. `deployment` は `jobs` に変更:
    - `commands` は `steps` にする
    - `commands` のリストの要素は `run:` にする
4. `machine` 以下の設定を `docker` にして `jobs` に書き加える
5. 適当に `workflows` を定義
    - `branch` の設定はこっちでする

あとは `checkout` やキャッシュ回りの設定、job 間でワークスペースを共有するために `persist_to_workspace` と `attach_workspace` を追記した。

### Hexo の更新

Node が古すぎて CircleCI の Docker イメージがなかった:

```
Build-agent version 0.1.1250-22bf9f5d (2018-12-12T11:32:15+0000)
Starting container circleci/node:4.4.5
  image cache not found on this host, downloading circleci/node:4.4.5

Error response from daemon: manifest for circleci/node:4.4.5 not found
```

ので、随分古い Node と Hexo を使っていたので更新した。

- Node: 4.4.5 -> 11.4.0
- Hexo: 3.3.5 -> 3.8.0

ここは特に問題なく動作した（たぶん）。

### Heroku と CircleCI

ここからがしんどい。。。

上の手順で適当に書き換えても動かなかった。
何がかというと、最終的なデプロイの部分だ。
まずは Staging である Heroku の部分。
CircleCI でデプロイしてみたら:

```
create mode 100644 public/tags/Twitter/index.html
create mode 100644 public/tags/guntohfes/index.html
The authenticity of host 'heroku.com (50.19.85.156)' can't be established.
RSA key fingerprint is SHA256:XXX/o.
Are you sure you want to continue connecting (yes/no)? Step was canceled
```

という状態で固まってしまった。
いろいろ調べてみたら、そもそも過去に設定したやり方はもう古いみたいだ（本当に？）。
なので [2.0 の資料](https://circleci.com/docs/2.0/deployment-integrations/#heroku)を参考にし `HEROKU_API_KEY` を使った方法にしようと思う。

Hexo の Heroku へのデプロイには [hexo-deployer-heroku](https://github.com/hexojs/hexo-deployer-heroku) というライブラリを使っている。
このライブラリで `HEROKU_API_KEY` 環境変数を埋め込むのは難しそうなので、hexo-deployer-heroku のコードを読んで同様の手順を CI で直接実行するようにした:

```sh
mkdir .deploy
cd .deploy
git init
cp -r ../public .
git add -A
git commit -m "Site updated"
git push -u https://heroku:$HEROKU_API_KEY@git.heroku.com/iggg-github-io-staging.git master -f
```

しかし、次のようなエラーが出た:

```
...
Writing objects: 100% (171/171), 4.58 MiB | 8.98 MiB/s, done.
Total 171 (delta 33), reused 0 (delta 0)
remote: Compressing source files... done.        
remote: Building source:        
remote:
remote: -----> App not compatible with buildpack: https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku/php.tgz        
remote:                
remote:  !     ERROR: Application not supported by this buildpack!        
remote:  !             
remote:  !     The 'heroku/php' buildpack is set on this application, but was        
remote:  !     unable to detect a PHP codebase.        
remote:  !             
remote:  !     A PHP app on Heroku requires a 'composer.json' at the root of        
remote:  !     the directory structure, or an 'index.php' for legacy behavior.        
remote:  !             
remote:  !     If you are trying to deploy a PHP application, ensure that one        
remote:  !     of these files is present at the top level directory.        
remote:  !             
remote:  !     If you are trying to deploy an application written in another        
remote:  !     language, you need to change the list of buildpacks set on your        
remote:  !     Heroku app using the 'heroku buildpacks' command.        
remote:  !             
remote:  !     For more information, refer to the following documentation:        
remote:  !     https://devcenter.heroku.com/articles/buildpacks        
remote:  !     https://devcenter.heroku.com/articles/php-support#activation
...
```

`git push` のところで起きている。
buildpack に `heroku/php` を指定しているが、この場合はワークスペースに `index.php` などがないとダメらしい。
hexo-deployer-heroku ではこの [assets](https://github.com/hexojs/hexo-deployer-heroku/tree/08f9fb7feab9a71e983ff0b5a05b6f1183a398f1/assets) の中身をコピーして `heroku/php` に合わせていた。
同じようにしてもいいが、別に PHP ではないので静的サイト用の buildpack に変更するようにした:

- [heroku/heroku-buildpack-static - GitHub](https://github.com/heroku/heroku-buildpack-static)

heroku-buildpack-static の設定ファイルとして `static.json` をワークスペースに置く必要がある。
なので、下記のコマンドを `git init` と `cp -r ../public .` の間で実行する:

```sh
echo "{ \"root\": \"public/\" }" > static.json
git add -A
git commit -m "First commit"
```

これで無事 Heroku にデプロイできた！

### GitHub と CircleCI

こっちも案の定ダメだった。
Heroku の時と同様に `yes/no` と聞かれて止まってしまう。
GitHub へのデプロイには [hexojs/hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git) を使っている。
Heroku の時みたいに同様の動作を直接書き込んでもいいが、できれば API トークンを使いたくないので、別の方法を調べた。
良さそうな CircleCI の質問ページがあった:

- [Git clone fails in Circle 2.0 - Build Environment - CircleCI Community Discussion](https://discuss.circleci.com/t/git-clone-fails-in-circle-2-0/15211/10)

次のようなのをデプロイする前に書けばいいらしい:

```sh
mkdir ~/.ssh/ && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" > ~/.ssh/config
```

エラーが変わった:

```
...
create mode 100644 tags/guntohfes/index.html
Warning: Permanently added 'github.com,192.30.253.112' (RSA) to the list of known hosts.

ERROR: The key you are authenticating with has been marked as read only.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
FATAL Something's wrong. Maybe you can find the solution here: http://hexo.io/docs/troubleshooting.html
Error: Warning: Permanently added 'github.com,192.30.253.112' (RSA) to the list of known hosts.

ERROR: The key you are authenticating with has been marked as read only.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.

   at ChildProcess.<anonymous> (/home/circleci/work/node_modules/hexo-util/lib/spawn.js:37:17)
   at ChildProcess.emit (events.js:189:13)
   at maybeClose (internal/child_process.js:978:16)
   at Socket.stream.socket.on (internal/child_process.js:395:11)
   at Socket.emit (events.js:189:13)
   at Pipe._handle.close (net.js:613:12)
Exited with code 2
```

これは設定している GitHub の SSH 鍵に書き込み権限が無いせいだ。
読み込みだけのやつはコンソールからボタン一つでできたが、書き込み権限付きの鍵は自分で作る必要がある。
以下の記事がわかりやすかった（似たような記事はたくさんあると思うけど）:

- [ircle CI で Github に write access 可能な Deploy key を設定する - Qiita](https://qiita.com/boushi-bird/items/6b6eb1d1ed6f6d3341e4)

これで無事本番にもデプロイできた！

## 残り作業

README とか Docker のところとかもほんとは整備しなきゃ。。。

## おしまい

更新は計画的に。
