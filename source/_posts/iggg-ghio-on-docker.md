---
title: IGGG の GitHub Pages の開発環境の Dockerイメージを作る
date: 2017-05-11 00:29:36
tags:
- Docker
- Node.js
categories: Web
cover: "/images/iggg-ghio-on-docker/dockercompose.jpg"
---

IGGG 名古屋支部のひげです。

久々に更新。

[Docker](https://www.docker.com/) がマイブームだったので、この [iggg.github.io](https://iggg.github.io/) の開発環境も Docker 化しようという話です。

基本的に話は簡単。
Windows上でやるせいで悪戦苦闘したという感じです。

## 開発環境

ワタシのパソコンはこんな感じ

- Windows10 Home
- Docker ToolBox
- Docker version 17.03.1-ce
- VirtualBox 5.1.18

Windows10 Home なので [Docker for Windows](https://docs.docker.com/docker-for-windows/) は使えず、仕方がないので VirtualBox を利用する [Docker ToolBox](https://www.docker.com/products/docker-toolbox) を使ってる。

## Dockerfile

いろいろ参考にしつつ、試した結果、これだけで良い。

```Dockerfile
FROM node:6
RUN npm install -g hexo-cli
```

このサイトは Hexo を使っているので、Node.js が必要だ。
なので、ベースは[公式の `node` Docker イメージ](https://hub.docker.com/_/node/)を使った。

これに，`hexo-cli` をインストールした。
`-g` はグローバル環境にインストールするというオプション。

あとは、

```
$ cd C:\Users\hoge\git\iggg.github.io
$ docker build -t iggg-ghio .
$ docker run -it -v /c/Users/hoge/git/iggg.github.io:/app -p 4000:4000 iggg-ghio /bin/bash
```

などして bash を実行する。
`-v` オプションで、現在のディレクトリを `/app` にマウントしている。

そして、Dockerコンテナ内で

```
$ npm install --no-bin-links
$ hexo clean
$ hexo server
```

を実行する。
ワークディレクトリにマウントするため、ビルド時に `npm install` をするわけにはいかない。
そのため、ビルド後のコンテナ内で `npm install` をしている。
また、`--no-bin-links` を指定しないと、Windows ではうまくいかない。

これで、VirtualBox で指定したIPアドレス(ToolBoxを使ってなければ localhost)の4000ポートにアクセスすれば見れるはずだ。

## docker-compose

`docker build` してからの操作が多いので `docker-compose` にまとめてしまおう。
本来の使い方とは異なってるが、こういう用途でも十分使える。

```
blog:
  build: .
  volumes:
    - .:/app
  ports:
    - "4000:4000"
  command: ./run.sh
  working_dir: /app
```

`run.sh` は

```txt
#! /bin/sh

npm install --no-bin-links
hexo clean
hexo server
```

Windowsだと、ここで `docker-compose up` しても次のようなエラーが返ってくる。

```
ERROR: for browser  Cannot create container for service browser: invalid bind mount spec "C:\\Users\\hoge\\git\\iggg.github.io:/app:rw": invalid volume specification: 'C:\Users\hoge\git\iggg.github.io:/app:rw'
ERROR: Encountered errors while bringing up the project.
```

原因はパスの指定の仕方で、相対パスで `.:/app` としてるとおかしくなる。
[ググった結果](http://qiita.com/ryo-endo/items/edc8c6f16e60b7533749)

```
COMPOSE_CONVERT_WINDOWS_PATHS=1
```

と書いてある `.env` ファイルをカレントディレクトリに置くことうまく動作した。

あと、よく怒られたのが、`run.sh` の改行文字で、LF でないといけないのに、Windows では時折 CRLF に書き換わる(gitで落としてきたときとか)。

## 実行

`docker-compose up` して特定のIPアドレスの4000ポートを見ればうまくいく。

![](/images/iggg-ghio-on-docker/dockercompose.jpg)

## おしまい

思いのほか時間かかった。
やっぱ Windows での開発はなかなかきついね。
